public with sharing class CheckEnvironmentBelongsToPipeline {
    private List<sObject> records;
    private String pipelineField;
    private String environmentField;

    // CTOR

    public CheckEnvironmentBelongsToPipeline(List<sObject> records) {
        this.records = records;
        pipelineField('Pipeline__c');
        environmentField('Environment__c');
    }

    // PUBLIC

    public CheckEnvironmentBelongsToPipeline pipelineField(String fieldName) {
        this.pipelineField = fieldName.startsWith(Settings.ns) ? fieldName : Settings.ns + fieldName;
        return this;
    }

    public CheckEnvironmentBelongsToPipeline environmentField(String fieldName) {
        this.environmentField = fieldName.startsWith(Settings.ns) ? fieldName : Settings.ns + fieldName;
        return this;
    }

    public void execute() {
        Map<Id, List<Deployment_Flow_Step__c>> connectionsByEnvironment = new DeploymentFlowStepsSelector().byEnvironment(environmentIds(records));

        for (SObject record : records) {
            Boolean validEnvironment = isValidEnvironment(record, connectionsByEnvironment);
            if (!validEnvironment) {
                record.addError(Label.EnvironmentDoesNotBelongToPipeline);
            }
        }
    }

    // PRIVATE

    private Set<Id> environmentIds(List<SObject> records) {
        Set<Id> result = new Set<Id>();

        for (SObject record : records) {
            Id environmentId = String.valueOf(record.get(environmentField));
            if (String.isNotBlank(environmentId)) {
                result.add(environmentId);
            }
        }

        return result;
    }

    private Boolean isValidEnvironment(SObject record, Map<Id, List<Deployment_Flow_Step__c>> connectionsByEnvironment) {
        Boolean result = false;

        Id environmentId = String.valueOf(record.get(environmentField));
        Id pipelineId = String.valueOf(record.get(pipelineField));
        if (String.isBlank(environmentId) || String.isBlank(pipelineId)) {
            result = true;
        } else if (connectionsByEnvironment.containsKey(environmentId)) {
            for (Deployment_Flow_Step__c connection : connectionsByEnvironment.get(environmentId)) {
                if (connection.Deployment_Flow__c == pipelineId) {
                    result = true;
                    break;
                }
            }
        }

        return result;
    }
}