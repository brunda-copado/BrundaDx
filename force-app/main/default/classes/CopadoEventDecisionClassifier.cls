global with sharing class CopadoEventDecisionClassifier extends CopadoEventGenerator {
    //Constants
    private enum CRITERIA_TYPES {
        equals,
        notequals,
        greater, 
        greaterorequals, 
        less, 
        lessorequals, 
        ischanged, 
        isnull
    }
    private static final Map<String, CRITERIA_TYPES> CRITERIA_TYPES_BY_STRING = new Map<String, CRITERIA_TYPES>();
    static {
        for(CRITERIA_TYPES value : CRITERIA_TYPES.values()){
            CRITERIA_TYPES_BY_STRING.put(value.name(), value);
        }
    }
    private static final List<String> SUPPORTED_TRIGGER_CONTEXTS = new List<String>{
        System.TriggerOperation.BEFORE_DELETE.name(),
        System.TriggerOperation.AFTER_INSERT.name(),  
        System.TriggerOperation.AFTER_UPDATE.name(),
        System.TriggerOperation.AFTER_UNDELETE.name()
    };
    private static final Boolean IS_DISABLED = Settings__c.getOrgDefaults().Disable_All_Copado_Events__c;
    //Non-constants
    private static List<EventGenerationDTO> events;
    private static String triggerObject;
    private static Map<String, Id> recordTypeNameById;
    private static String triggeringAction;
    private static Map<Id, SObject> oldMap;
    private static Map<Id, SObject> newMap;
    private static Map<Id, SObject> records;
    private static Map<Id, SObject> eventRecords;
    private static String subscriberCode;
    private static Boolean disableEventGeneration = false;
    private static Boolean isTriggerEnforced = true;
    //Global methods for extension packages use
    global static void toggleEventGeneration(Boolean disable){
        disableEventGeneration = disable;
    }
    global static List<Object> getEventDecisions(Map<Id, SObject> newRecords, Map<Id, SObject> oldRecords, String triggerContext){
        assignVariables(newRecords, oldRecords, triggerContext, null, null);
        return checkConditions();
    }
    global static List<Object> getEventDecisions(Map<Id, SObject> newRecords, Map<Id, SObject> oldRecords, String triggerContext, String code){
        assignVariables(newRecords, oldRecords, triggerContext, code, null);
        return checkConditions();
    }
    global static List<Object> getEventDecisions(Map<Id, SObject> newRecords, Map<Id, SObject> oldRecords, String triggerContext, String code, String objectApi){
        assignVariables(newRecords, oldRecords, triggerContext, code, objectApi);
        return checkConditions();
    }

    private static void assignVariables(Map<Id, SObject> newRecords, Map<Id, SObject> oldRecords, String triggerContext, String code, String objectApi){
        isTriggerEnforced = false;
        triggeringAction = triggerContext;
        oldMap = oldRecords;
        newMap = newRecords;
        subscriberCode = code;
        triggerObject = objectApi;
    }

    public static void execute(){
        if(!disableEventGeneration){
            checkConditions();
            generateEvents();
        }
    }

    public static List<EventGenerationDTO> checkConditions(){
        validate();
        setVariables();
        ConditionsDTO conditions = getCopadoEventConditions();
        for(Data_Change_Event_Condition__c condition : conditions.conditionsByIds.values()){
            if(isTriggerEnforced || (!isTriggerEnforced && CopadoEventCheckpoint.isEnabled(triggeringAction, new List<Data_Change_Event_Condition__c>{condition}
        ))){
                List<SObject> sObjects = new List<SObject>();
                if(condition.Allow_All_Data__c){
                    sObjects.addAll(records.values());
                } else {
                    sObjects.addAll(
                        checkConditionItems(
                            conditions, 
                            condition
                        )
                    );
                }
                if(!sObjects.isEmpty()){
                    events.add(
                        new EventGenerationDTO(sObjects, triggeringAction, condition.Subscriber_Code__c, triggerObject)
                    );
                }
            }
        }
        return events;
    }

    public static void generateEvents(){
        if(null != events && !events.isEmpty()){
            new CopadoEventGenerator().generate(events);
        }
    }

    private static List<SObject> checkConditionItems(ConditionsDTO conditions, Data_Change_Event_Condition__c condition){
        List<Data_Change_Event_Condition_Items__c> conditionItems = conditions.itemsByConditionIds.get(condition.Id);
        List<SObject> sObjects = new List<SObject>();
        for(Id recordId : records.keyset()){
            if(validateRecordType(condition, recordId)){
                String conditionLogic = condition.Condition_Logic__c;
                if(!String.isBlank(conditionLogic) && null != conditionItems){
                    Boolean decision = PredicateBooleanExpression.eval(
                        preparePredicateText(
                            conditionItems, 
                            conditionLogic,
                            recordId
                        )
                    );
                    if(decision){
                        sObjects.add(
                            eventRecords.get(recordId)
                        );
                    }
                } else break;
            }
        }
        return sObjects;
    }

    /**
     * validates if the committed record on current iteration belongs to desired recordType
     * @see checkConditionItems
     * @return decision based on recordType check
     */
    private static Boolean validateRecordType(Data_Change_Event_Condition__c condition, Id recordId){
        return null == condition.Record_Type_Developer_Name__c || recordTypeNameById.get(condition.Record_Type_Developer_Name__c) == records.get(recordId).get('RecordTypeId');
    }

    /**
     * return format: TRUE OR ((FALSE AND TRUE) OR (TRUE AND FALSE))
     * @return record based filter logic replace by Boolean
     */
    private static String preparePredicateText(List<Data_Change_Event_Condition_Items__c> conditionItems, String conditionLogic, Id recordId){
        if(!validateLogicAndConditionItems(conditionItems, conditionLogic)){
            System.debug('Skipping condition : ' + conditionItems[0].Event_Condition_Id__c + ', condition items are not valid with the condition logic! Please re-check your condition related records.');
            return String.valueOf('FALSE');
        }
        for(Data_Change_Event_Condition_Items__c conditionItem : conditionItems){
            List<String> splittedCondition = conditionItem.Filter_Condition__c.split(',');
            conditionLogic = conditionLogic.replace(
                String.valueOf(conditionItem.Filter_Order__c), 
                String.valueOf(getDecisions(splittedCondition, recordId))
            );
        }
        return conditionLogic;
    }

    /**
     * checks missing conditions item based on condition filter
     * eg : 1 And (2 Or 3) while we have only 2 items with order 1 and 2, 3 is missing
     * @return boolean base on a validity 
     */
    private static Boolean validateLogicAndConditionItems(List<Data_Change_Event_Condition_Items__c> conditionItems, String conditionLogic){
        conditionLogic = conditionLogic.toUpperCase();
        conditionLogic = conditionLogic.replace('AND', '').replace('OR', '').replace('(', '').replace(')', '').deleteWhitespace();
        for(Data_Change_Event_Condition_Items__c conditionItem : conditionItems){
            conditionLogic = conditionLogic.replace(String.valueOf(conditionItem.Filter_Order__c), '');
        }
        if(conditionLogic.length() > 0){
            return false;
        } else {
            return true;
        }
    }

    /**
     * sends criteria Item to correct handler based on operator
     * @return : decision 
     */
    private static Boolean getDecisions(List<String> splittedCondition, Id recordId){
        CRITERIA_TYPES operator = CRITERIA_TYPES_BY_STRING.get(splittedCondition[1].deleteWhitespace());
        switch on operator {
            when equals {
                return handleEquals(splittedCondition, recordId);
            }
            when notequals {
                return handleNotEquals(splittedCondition, recordId);
            }
            when greater {
                return handleGreater(splittedCondition, recordId);
            }
            when greaterorequals {
                return handleGreaterOrEquals(splittedCondition, recordId);
            }
            when less {
                return handleLess(splittedCondition, recordId);
            }
            when lessorequals {
                return handleLessOrEquals(splittedCondition, recordId);
            }
            when ischanged {
                return handleChange(splittedCondition, recordId);
            }
            when isnull {
                return handleNull(splittedCondition, recordId);
            }
            when else {
                throw new EventException(Label.UNSUPPORTED_HANDLE_TYPE);
            }
        }
    }
    
    /**
     *  Custom Settings Format: copado__Status__c,equals,'In progress'
     *  @return decision  
     *  @see getDecisions
     */
    private static Boolean handleEquals(List<String> splittedCondition, Id recordId){
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(triggerObject).getDescribe().fields.getMap();
        ConvertTypes ct = new ConvertTypes(objectFields.get(splittedCondition[0]));
        return records.get(recordId).get(splittedCondition[0].deleteWhitespace()) == ct.getConverter().getValue(splittedCondition[2]);
    }
    /**
     *  Custom Settings Format: copado__Status__c,notequals,'In progress'
     *  @return decision  
     *  @see getDecisions
     */
    private static Boolean handleNotEquals(List<String> splittedCondition, Id recordId){
        return !handleEquals(splittedCondition, recordId);
    }
    /**
     *  Custom Settings Format: copado__Quantity__c,greater,5
     *  @return decision  
     *  @see getDecisions
     */
    private static Boolean handleGreater(List<String> splittedCondition, Id recordId){
        return Integer.valueOf(records.get(recordId).get(splittedCondition[0].deleteWhitespace())) > Integer.valueOf(splittedCondition[2]);
    }
    /**
     *  Custom Settings Format: copado__Quantity__c,greaterorequals,5
     *  @return decision  
     *  @see getDecisions
     */
    private static Boolean handleGreaterOrEquals(List<String> splittedCondition, Id recordId){
        return Integer.valueOf(records.get(recordId).get(splittedCondition[0].deleteWhitespace())) >= Integer.valueOf(splittedCondition[2]);
    }
    /**
     *  Custom Settings Format: copado__Quantity__c,less,5
     *  @return decision  
     *  @see getDecisions
     */
    private static Boolean handleLess(List<String> splittedCondition, Id recordId){
        return Integer.valueOf(records.get(recordId).get(splittedCondition[0].deleteWhitespace())) < Integer.valueOf(splittedCondition[2]);
    }
    /**
     *  Custom Settings Format: copado__Quantity__c,lessorequals,5
     *  @return decision  
     *  @see getDecisions
     */
    private static Boolean handleLessOrEquals(List<String> splittedCondition, Id recordId){
        return Integer.valueOf(records.get(recordId).get(splittedCondition[0].deleteWhitespace())) <= Integer.valueOf(splittedCondition[2]);
    }
    /**
     *  Custom Settings Format: copado__Status__c,ischanged,true
     *  @return decision
     *  @see getDecisions
     */ 
    private static Boolean handleChange(List<String> splittedCondition, Id recordId){
        if(triggeringAction.equalsIgnoreCase(System.TriggerOperation.AFTER_UPDATE.name())){
            if(null != newMap && null != oldMap){
                Boolean isChanged = newMap.get(recordId).get(splittedCondition[0].deleteWhitespace()) != oldMap.get(recordId).get(splittedCondition[0].deleteWhitespace());
                return splittedCondition[2].equalsIgnoreCase('true') ? isChanged : !isChanged;
            } else {
                return true;
            }
        } else {
            return true; 
        }
    }
    /**
     *  Custom Settings Format: copado__Status__c,isnull,true
     *  @return decision
     *  @see getDecisions
     */  
    private static Boolean handleNull(List<String> splittedCondition, Id recordId){
        Boolean isNull =  null == newMap.get(recordId).get(splittedCondition[0].deleteWhitespace());
        return splittedCondition[2].equalsIgnoreCase('true') ? isNull : !isNull;
    }
    
    private static void setVariables(){
        events = new List<EventGenerationDTO>();
        assignMaps();
        getTriggeringAction();
        getConditionRecords();
        getEventRecords();
        getTriggerObject();
        getRecordTypeNameById();
    }
    
    private static void assignMaps(){
        if(isTriggerEnforced){
            oldMap = Trigger.oldMap;
            newMap = Trigger.newMap;
        }
    }

    private static void getTriggeringAction() {
        if(isTriggerEnforced){
            String action = Trigger.operationType.name();
            if(!SUPPORTED_TRIGGER_CONTEXTS.contains(action)) {
                throw new EventException(Label.UNSUPPORTED_TRIGGER_CONTEXT);
            }
            triggeringAction = action;
        } 
    }

    //to use on condition and record comparison
    //need newValues for equals
    private static void getConditionRecords(){
        if(triggeringAction.equalsIgnoreCase(System.TriggerOperation.BEFORE_DELETE.name())){
            records = oldMap;
        } else { 
            records = newMap;
        }
    }

    //to use on Event creation for OldValues
    private static void getEventRecords(){
        if(triggeringAction.equalsIgnoreCase(System.TriggerOperation.AFTER_INSERT.name()) || triggeringAction.equalsIgnoreCase(System.TriggerOperation.AFTER_UNDELETE.name())){
            eventRecords = newMap;
        } else { 
            eventRecords = oldMap;
        }
    }
    
    private static void getTriggerObject() {
        if(isTriggerEnforced || (String.isBlank(triggerObject) && !isTriggerEnforced)){
            triggerObject = records.values()[0].Id.getSObjectType().getDescribe().getName();
        }
    }

    private static void getRecordTypeNameById() {
        recordTypeNameById = new Map<String, Id>();
        for(RecordType recordType : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = : triggerObject]){
            recordTypeNameById.put(recordType.DeveloperName, recordType.Id);
        }
    }

    private static ConditionsDTO getCopadoEventConditions() {
        ConditionsDTO conditions = new ConditionsDTO();
        Map<Id, Data_Change_Event_Condition__c> conditionsByIds = new Map<Id, Data_Change_Event_Condition__c>();
        Map<Id, List<Data_Change_Event_Condition_Items__c>> itemsByConditionIds = new Map<Id, List<Data_Change_Event_Condition_Items__c>>();
        List<Data_Change_Event_Condition__c> conditionItems;
        if(String.isEmpty(subscriberCode)){
            conditionItems = [SELECT Id, Name, Delete__c, Insert__c, Update__c, Undelete__c, Allow_All_Data__c, Condition_Logic__c, Object_Api_Name__c, Record_Type_Developer_Name__c, Subscriber_Code__c FROM Data_Change_Event_Condition__c WHERE Object_Api_Name__c = : triggerObject];
        } else {
            conditionItems = [SELECT Id, Name, Delete__c, Insert__c, Update__c, Undelete__c, Allow_All_Data__c, Condition_Logic__c, Object_Api_Name__c, Record_Type_Developer_Name__c, Subscriber_Code__c FROM Data_Change_Event_Condition__c WHERE Object_Api_Name__c = : triggerObject AND Subscriber_Code__c = : subscriberCode];
        }
        
        for(Data_Change_Event_Condition__c condition : conditionItems){
            itemsByConditionIds.put(condition.Id, null);
            conditionsByIds.put(condition.Id, condition);
        }
        conditions.itemsByConditionIds = getCopadoEventConditionItems(itemsByConditionIds, conditionsByIds);
        conditions.conditionsByIds = conditionsByIds;
        return conditions;
    }

    private static Map<Id, List<Data_Change_Event_Condition_Items__c>> getCopadoEventConditionItems(Map<Id, List<Data_Change_Event_Condition_Items__c>> itemsByConditionIds, Map<Id, Data_Change_Event_Condition__c> conditionsByIds){
        for(Data_Change_Event_Condition_Items__c conditionItem : [SELECT Id, Event_Condition_Id__c, Filter_Condition__c, Filter_Order__c FROM Data_Change_Event_Condition_Items__c WHERE Event_Condition_Id__c IN : conditionsByIds.keyset() Order By Event_Condition_Id__c, Filter_Order__c ASC]){
            List<Data_Change_Event_Condition_Items__c> tempList = new List<Data_Change_Event_Condition_Items__c>(); 
            if(null != itemsByConditionIds.get(conditionItem.Event_Condition_Id__c)){
                tempList = itemsByConditionIds.get(conditionItem.Event_Condition_Id__c);
            }
            tempList.add(conditionItem);
            itemsByConditionIds.put(conditionItem.Event_Condition_Id__c, tempList);
        }
        return itemsByConditionIds;
    }
    
    private static void validate(){
        isTrigger();
        isDisabled();
    }    

    private static void isTrigger(){
        if(!Trigger.isExecuting && isTriggerEnforced){
            throw new EventException(Label.OUT_OF_TRIGGER_CONTEXT);
        }
    }

    private static void isDisabled(){
        if(IS_DISABLED){
            throw new EventException(Label.EVENT_DISABLED_ON_ORGANIZATION);
        }
    }

    public class ConditionsDTO {
        Map<Id, List<Data_Change_Event_Condition_Items__c>> itemsByConditionIds;
        Map<Id, Data_Change_Event_Condition__c> conditionsByIds;
    }

    public class EventGenerationDTO {
        String baseObject;
        List<SObject> records;
        String triggeringAction;
        String subscriberCode;
        public EventGenerationDTO(List<SObject> records, String triggeringAction, String subscriberCode, String baseObject){
            this.records = records;
            this.triggeringAction = triggeringAction;
            this.subscriberCode = subscriberCode;
            this.baseObject = baseObject;
        }

        public List<SObject> getRecords() {
            return records;
        }

        public String getActionType() {
            return triggeringAction;
        }

        public String getCode() {
            return subscriberCode;
        }

        public String getBaseObject(){
            return baseObject;
        }
    }

    public class EventException extends Exception {}
}