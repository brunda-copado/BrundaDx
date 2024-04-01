public with sharing class DataStepValidator {
    private Id stepId;

    public DataStepValidator(Id stepId) {
        this.stepId = stepId;
    }

    public void validate() {
        Id sourceOrg = getDeploymentSourceOrg();
        List<Id> destinationOrgs = getDeploymentDestinationOrgs();
        List<Id> dataTemplateIds = getDataTemplates();

        DataTemplateDeploymentValidator validator = new DataTemplateDeploymentValidator(dataTemplateIds, sourceOrg, destinationOrgs);
        DataTemplateDeploymentValidationResult result = validator.validate();
        DataStepValidatorResultHandler resultHandler = new DataStepValidatorResultHandler(this.stepId);
        resultHandler.handle(result);
    }

    private Step__c getStep() {
        List<Step__c> steps = new StepsSelector().byId(new List<Id>{ this.stepId });
        return !steps.isEmpty() ? steps[0] : null;
    }

    private Id getDeploymentSourceOrg() {
        Step__c step = getStep();
        return step.Deployment__r.From_Org__c;
    }

    private List<Id> getDeploymentDestinationOrgs() {
        Step__c step = getStep();
        List<Destination_Org__c> destinationOrgs = new DestinationOrgsSelector().byDeploymentId(new List<Id>{ step.Deployment__c });
        List<Id> destinationOrgIds = new List<Id>();
        for (Destination_Org__c destinationOrg : destinationOrgs) {
            destinationOrgIds.add(destinationOrg.To_Org__c);
        }
        return destinationOrgIds;
    }

    private List<Id> getDataTemplates() {
        List<Id> dataTemplateIds = new List<Id>();
        Id dataTemplateId = getDataTemplate();
        dataTemplateIds.add(dataTemplateId);

        DataTemplatesService dataTemplatesService = new DataTemplatesService(new Set<Id>{ dataTemplateId });
        dataTemplateIds.addAll(dataTemplatesService.getRelatedDataTemplates(dataTemplateId));

        return dataTemplateIds;
    }

    private Id getDataTemplate() {
        DataStepData stepData = getStepData();

        Id dataTemplateId = getDataTemplateFromStepData(stepData);

        return dataTemplateId;
    }

    private DataStepData getStepData() {
        Step__c step = getStep();
        DataStepData stepData = (DataStepData) JSON.deserialize(step.dataJSON__c, DataStepData.class);
        return stepData;
    }

    private Id getDataTemplateFromStepData(DataStepData stepData) {
        Id dataTemplateId;
        if (String.isNotBlank(stepData.dataTemplateId)) {
            dataTemplateId = stepData.dataTemplateId;
        } else if (stepData.source != null) {
            switch on stepData.source.type {
                when DATASET {
                    Id dataSetId = stepData.source.id;
                    DataSetsService dataSetsService = new DataSetsService(new Set<Id>{ dataSetId });
                    Data_Set__c dataSet = dataSetsService.getDataSet(dataSetId);
                    if (dataSet != null) {
                        dataTemplateId = dataSet.Data_Template__c;
                    }
                }
            }
        }
        return dataTemplateId;
    }


}