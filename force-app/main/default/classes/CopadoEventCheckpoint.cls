public inherited sharing class CopadoEventCheckpoint {
    private static final String triggerObject;
    private static final List<Data_Change_Event_Condition__c> CONDITIONS;
    private static final String CUSTOM_FIELD_APPENDIX = '__c';
    static{
        try {
            if(Trigger.isExecuting){
                triggerObject = Trigger.isDelete ? String.valueOf(Trigger.old.getSObjectType()) : String.valueOf(Trigger.new.getSObjectType());
                CONDITIONS = getRelatedEventAllowances((triggerObject).toLowerCase());
            }
        } catch(Exception ex){
            System.debug('Exception details: ' + ex.getMessage());
        }
    }
    
    public static void executeEventGeneration(){
        try {
            if(isEnabled()){
                CopadoEventDecisionClassifier.execute();
            }
        } catch(Exception ex){
            System.debug('There is something wrong in the Event generation classes. Check CopadoEventDecisionClassifier and CopadoEventGenerator! ' + ex.getMessage());
        }
    }
    /**
     * controls Data_Change_Event_Condition__c custom setting records to check trigger context permission
     * @return event creation allowance
     */
    private static Boolean isEnabled(){
        //example format : BEFORE_DELETE
        String context = Trigger.operationType.name().split('_')[1];
        if(null != CONDITIONS){
            for(Data_Change_Event_Condition__c condition : CONDITIONS){
                if(Boolean.valueOf(condition.get(context+CUSTOM_FIELD_APPENDIX))){
                    return true;
                }
            }
        }
        return false;
    }

    public static Boolean isEnabled(String paramContext, List<Data_Change_Event_Condition__c> conditions){
        //example format : BEFORE_DELETE
        String context = paramContext.split('_')[1];
        if(null != CONDITIONS){
            for(Data_Change_Event_Condition__c condition : conditions){
                if(Boolean.valueOf(condition.get(context+CUSTOM_FIELD_APPENDIX))){
                    return true;
                }
            }
        }
        return false;
    }
    /**
     * returns related Data_Change_Event_Condition__c record based on a trigger object
     * in use on project, release, sprint, epic, userStory handlers
     * @param object api name
     * @return List<Data_Change_Event_Condition__c> related to current Trigger object
     */
    public static List<Data_Change_Event_Condition__c> getRelatedEventAllowances(String objectApi){
        return [SELECT Insert__c, Update__c, Delete__c, Undelete__c FROM Data_Change_Event_Condition__c WHERE Object_Api_Name__c = : objectApi];
    }
}