/**
 * @description : generic copado platform event generator   
 */
public virtual class CopadoEventGenerator {
    @Testvisible private static List<Data_Change_Event__e> eventsToPublish;
    @Testvisible private static String previousBaseObject;
    @Testvisible private static String previousActionType;
    protected void generate(List<CopadoEventDecisionClassifier.EventGenerationDTO> events){
        validateDuplication(events[0].getBaseObject(), events[0].getActionType());
        for(CopadoEventDecisionClassifier.EventGenerationDTO event : events){
            for(SObject record : event.getRecords()){
                eventsToPublish.add(
                    new DataChangeEvent()
                    .id((Id)record.get('Id'))
                    .code(event.getCode()) 
                    .action(event.getActionType())
                    .oldValue(JSON.serialize(record))
                    .getDataChangeEvent()
                );
            }
        }
        checkPlatformEventLimits();
        List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
    }

    private void checkPlatformEventLimits(){
        Map<String,System.OrgLimit> limitsMap = OrgLimits.getMap();
        System.OrgLimit apiRequestsLimit = limitsMap.get('HourlyPublishedPlatformEvents');
        if((apiRequestsLimit.getValue() + eventsToPublish.size()) > apiRequestsLimit.getLimit()){
            throw new EventGenerationException(
                String.format(Label.HourlyPlatformEventPublishLimit, 
                new List<String>{
                    String.valueOf(apiRequestsLimit.getLimit())
                })
            );
        }
    }

    private void validateDuplication(String baseObject, String actionType){
        if(previousBaseObject == baseObject && previousActionType == actionType){
            throw new EventGenerationException(Label.DUPLICATE_EVENT_CREATION);
        } else {
            previousBaseObject = baseObject;
            previousActionType = actionType;
            eventsToPublish = new List<Data_Change_Event__e>();
        }
    }
    
    public class DataChangeEvent {
        private Data_Change_Event__e event { 
            get {
                if(null == event){
                    event = new Data_Change_Event__e();
                }
                return event;
            } private set;
        }
        private List<String> oldSupportedContexts = new List<String>{
            'BEFORE_DELETE',
            'AFTER_UPDATE'
        };

        public Data_Change_Event__e getDataChangeEvent(){
            return event;
        }
        
        public DataChangeEvent id(Id instanceId) {
            event.Record_ID__c = instanceId;
            event.Base_Object__c = instanceId.getSObjectType().getDescribe().getName();
            return this;
        }

        public DataChangeEvent code(String code){
            event.Subscriber_Code__c = code;
            return this;
        }
    
        public DataChangeEvent action(String action){
            event.Triggering_Action__c = action;
            return this;
        }

        public DataChangeEvent oldValue(String value) {
            if(oldSupportedContexts.contains(event.Triggering_Action__c)){
                event.Old_Value__c = value;
            }
            return this;
        }
    }

    private class PlatformLimitDTO {
        public Integer Max;
        public Integer Remaining;
    }

    public class EventGenerationException extends Exception {}
}