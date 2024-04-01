public with sharing class DataDeployer {
    private static final String ADVANCED_DEPLOYMENT_RECORD_TYPE_ID = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName()
        .get('Advanced_multi_step')
        .getRecordTypeId();
    private static final String DATA_TEMPLATE_TYPE = 'Data Template';
    private static final String SCHEDULED_STATUS = 'Scheduled';

    private DataDeployRequest deployRequest;
    private DataSetsService dataSetsService;

    private Deployment__c dataDeployment;

    private Id currentOrgCredential {
        get {
            if (currentOrgCredential == null) {
                String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
                List<Org__c> orgs = new OrgsSelector().bySfdcOrgId(new List<String>{ sfdcOrgId });
                if (orgs.isEmpty()) {
                    throw new DataDeployerException(Label.Error_Getting_Current_Org_Credential);
                }
                currentOrgCredential = orgs[0].Id;
            }
            return currentOrgCredential;
        }
        set;
    }

    public DataDeployer(DataDeployRequest deployRequest) {
        List<String> errors = validateRequest(deployRequest);
        if (!errors.isEmpty()) {
            throw new DataDeployerException(String.join(errors, ', '));
        }
        this.deployRequest = deployRequest;
        initDataSetsService();
    }

    public Id execute() {
        this.dataDeployment = createDeployment();
        Utilities.Secure_DML(this.dataDeployment, Utilities.DML_Action.INS, Schema.SObjectType.Deployment__c);

        Destination_Org__c destinationOrg = createDestinationOrg();
        Utilities.Secure_DML(destinationOrg, Utilities.DML_Action.INS, Schema.SObjectType.Destination_Org__c);

        Step__c step = createStep();
        Utilities.Secure_DML(step, Utilities.DML_Action.INS, Schema.SObjectType.Step__c);

        if (this.deployRequest.getDeployNow() == true) {
            Deployment__c updatedDeployment = updateDeploymentStatus();
            Utilities.Secure_DML(updatedDeployment, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment__c);

            if (this.deployRequest.getDestinationType() == DataDeployRequest.Destination.DATASET) {
                Data_Set__c updatedDataSet = updateDataSetLastExecutionDetails();
                Utilities.Secure_DML(updatedDataSet, Utilities.DML_Action.UPD, Schema.SObjectType.Data_Set__c);
            }

            deploy();
        }

        return this.dataDeployment.Id;
    }

    private List<String> validateRequest(DataDeployRequest request) {
        List<String> errors = new List<String>();
        if (request.getSourceType() == null) {
            errors.add(Label.Data_Source_Required);
        }
        if (request.getDestinationType() == null) {
            errors.add(Label.Data_Destination_Required);
        }
        if (request.getSourceType() == DataDeployRequest.Source.ENVIRONMENT && request.getDataTemplateId() == null) {
            errors.add(Label.Data_Template_Id_Required);
        }
        if (request.getSourceType() == DataDeployRequest.Source.DATASET && request.getSourceDataSetId() == null) {
            errors.add(Label.Source_Data_Set_Id_Required);
        }
        if (request.getSourceType() == DataDeployRequest.Source.BRANCH && request.getSourceBranchName() == null) {
            errors.add(Label.Source_Branch_Name_Required);
        }
        if (request.getDestinationType() == DataDeployRequest.Destination.DATASET && request.getDestinationDataSetId() == null) {
            errors.add(Label.Destination_Data_Set_Id_Required);
        }
        if (request.getDestinationType() == DataDeployRequest.Destination.BRANCH && request.getDestinationBranchName() == null) {
            errors.add(Label.Destination_Branch_Name_Required);
        }
        return errors;
    }

    private void initDataSetsService() {
        Set<Id> dataSetIds = new Set<Id>();
        if (this.deployRequest?.getSourceDataSetId() != null) {
            dataSetIds.add(this.deployRequest.getSourceDataSetId());
        }
        if (this.deployRequest?.getDestinationDataSetId() != null) {
            dataSetIds.add(this.deployRequest.getDestinationDataSetId());
        }
        this.dataSetsService = new DataSetsService(dataSetIds);
    }

    private Deployment__c createDeployment() {
        Id sourceCrendentialId;
        if (this.deployRequest.getSourceType() == DataDeployRequest.Source.DATASET) {
            Id dataSetId = this.deployRequest?.getSourceDataSetId();
            sourceCrendentialId = getDataSetSource(dataSetId);
        } else {
            sourceCrendentialId = this.deployRequest.getSourceCredentialId() != null
                ? this.deployRequest.getSourceCredentialId()
                : currentOrgCredential;
        }

        String deploymentName = getDeploymentName();

        Deployment__c deployment = new Deployment__c(
            Name = deploymentName,
            From_Org__c = sourceCrendentialId,
            RecordTypeId = ADVANCED_DEPLOYMENT_RECORD_TYPE_ID
        );

        return deployment;
    }

    private Destination_Org__c createDestinationOrg() {
        Id destinationCredentialId = this.deployRequest.getDestinationCredentialId() != null
            ? this.deployRequest.getDestinationCredentialId()
            : this.dataDeployment.From_Org__c;

        Destination_Org__c destinationOrg = new Destination_Org__c(Deployment__c = this.dataDeployment.Id, To_Org__c = destinationCredentialId);

        return destinationOrg;
    }

    private Step__c createStep() {
        String dataJson = generateDataJson();

        String stepName = getStepName();

        String parentId = getStepParentId();

        Step__c dataTemplateStep = new Step__c(
            dataJson__c = dataJson,
            Deployment__c = this.dataDeployment.Id,
            Name = stepName,
            Type__c = DATA_TEMPLATE_TYPE,
            ParentId__c = parentId
        );

        return dataTemplateStep;
    }

    private String generateDataJson() {
        DataStepData data = new DataStepData(this.deployRequest);
        return JSON.serialize(data, true);
    }

    private Deployment__c updateDeploymentStatus() {
        Deployment__c updatedDeployment = new Deployment__c(
            Id = this.dataDeployment.Id,
            Status__c = SCHEDULED_STATUS,
            Date__c = System.now(),
            Deployment_command_sent__c = null
        );

        return updatedDeployment;
    }

    private Data_Set__c updateDataSetLastExecutionDetails() {
        Data_Set__c updatedDataSet = new Data_Set__c(
            Id = this.deployRequest.getDestinationDataSetId(),
            Last_Generated_Date__c = System.now(),
            Execution_Job__c = this.dataDeployment.Id,
            Source_Org__c = this.dataDeployment.From_Org__c
        );

        return updatedDataSet;
    }

    private void deploy() {
        DeployAPI.deploy(new List<Id>{ this.dataDeployment.Id }, null);
    }

    private String getDeploymentName() {
        String defaultTaskName = getDefaultTaskName();
        return String.isNotBlank(defaultTaskName) ? defaultTaskName : 'Data Deploy';
    }

    private String getStepName() {
        String defaultTaskName = getDefaultTaskName();
        return String.isNotBlank(defaultTaskName) ? defaultTaskName : 'Step 1';
    }

    private String getDefaultTaskName() {
        String result;
        if (this.deployRequest.getDestinationType() == DataDeployRequest.Destination.DATASET) {
            String dataSetName = getDataSetName(this.deployRequest.getDestinationDataSetId());
            if (String.isNotBlank(dataSetName)) {
                result = 'Generate' + ' ' + dataSetName;
            }
        } else if (this.deployRequest.getSourceType() == DataDeployRequest.Source.DATASET) {
            String dataSetName = getDataSetName(this.deployRequest.getSourceDataSetId());
            if (String.isNotBlank(dataSetName)) {
                result = 'Deploy' + ' ' + dataSetName;
            }
        }
        return result;
    }

    private String getStepParentId() {
        String result;
        if (this.deployRequest.getDestinationType() == DataDeployRequest.Destination.DATASET) {
            result = this.deployRequest.getDestinationDataSetId();
        } else if (this.deployRequest.getSourceType() == DataDeployRequest.Source.DATASET) {
            result = this.deployRequest.getSourceDataSetId();
        }
        return result;
    }

    private String getDataSetName(Id dataSetId) {
        return this.dataSetsService.getDataSet(dataSetId)?.Name;
    }

    private Id getDataSetSource(Id dataSetId) {
        return this.dataSetsService.getDataSet(dataSetId)?.Source_Org__c;
    }

    public class DataDeployerException extends Exception {
    }
}