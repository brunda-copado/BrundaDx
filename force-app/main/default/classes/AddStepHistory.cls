public with sharing class AddStepHistory {

    private List<Step__c> steps;
    private String operationType;
    private Map<Id, Step__c> oldSteps;

    // CONSTRUCTOR

    public AddStepHistory(List<Step__c> steps) {
        this.steps = steps;
        this.operationType = 'Created';
    }


    public AddStepHistory(List<Step__c> steps, Map<Id, Step__c> oldSteps, String operationType) {
        this.steps = steps;
        this.oldSteps = oldSteps;
        this.operationType = operationType;
    }


    // PUBLIC
    
    public void execute() {
        List<Deployment_History__c> histories;

        if(operationType == 'Updated') {
            histories = asUpdateHistories();
        }
        else {
            histories = asHistories();
        }

        insert histories;
    }

    // PRIVATE

    private List<Deployment_History__c> asHistories() {
        List<Deployment_History__c> result = new List<Deployment_History__c>();

        for (Step__c step : steps) {
            Deployment_History__c history = new Deployment_History__c();
            history.Deployment_Id__c = step.Deployment__c;
            history.Deployment__c = step.Deployment__c;
            history.Date__c = System.now();
            history.Event__c = operationType;
            history.Object__c = 'Step';
            history.User__c = UserInfo.getUserId();
            history.Field__c = 'Name';

            if (operationType == 'Created') {
                history.New_Value__c = step.Name;
            }
            else if (operationType == 'Deleted') {
                history.Old_Value__c = step.Name;
            }

            result.add(history);
        }

        return result;
    }

    private List<Deployment_History__c> asUpdateHistories() {
        List<Deployment_History__c> result = new List<Deployment_History__c>();

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Step__c.fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
            String label = field.getLabel();

            if (field.isUpdateable()) {
                for (Step__c step : steps) {
                    Step__c oldStep = oldSteps.get(step.Id);
                    
                    if (oldStep.get(fieldName) != step.get(fieldName)) {
                        result.add( asUpdateHistory(step, oldStep, field));
                    }
                }
            }
        }

        return result;
    }

    private Deployment_History__c asUpdateHistory(Step__c step, Step__c oldStep, DescribeFieldResult field) {
        Deployment_History__c result = new Deployment_History__c();
        
        String fieldName = field.getName();
        String label = field.getLabel();
        
        result.Deployment__c = oldStep.Deployment__c;
        result.Deployment_Id__c = oldStep.Deployment__c;
        result.Date__c = System.now();
        result.Event__c = operationType;
        result.Object__c = 'Step';
        result.Field__c = label;
        result.User__c = UserInfo.getUserId();
        result.New_Value__c = (step.get(fieldName) != null ? String.valueOf(step.get(fieldName)).left(255) : null);
        result.Old_Value__c = (oldStep.get(fieldName) != null ? String.valueOf(oldStep.get(fieldName)).left(255) : null);

        return result;
    }
}