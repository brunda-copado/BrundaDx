public with sharing class CheckCBMLicense {
    // TODO: remove this comment
    private List<Deployment_Flow__c> pipelines;
    private static LicenseManagerController licenses = new LicenseManagerController();

    // CONSTRUCTOR

    public CheckCBMLicense(List<Deployment_Flow__c> pipelines) {
        this.pipelines = filterValid(pipelines);
    }


    // PUBLIC

    public void execute() {
        Boolean isBranchManagementEnabled = FeatureHelper.isFeatureEnabled('Branch Management');
        Integer totalSteps = existingSteps() + newSteps();
        
        Integer allowedSteps = licenses.cbmBranchesAvailable;
        
        for(Deployment_Flow__c pipeline : pipelines) {
            if(!isBranchManagementEnabled) {
                pipeline.addError(Label.BRANCH_MGMT_NOT_ENABLED);
            }
            else if(totalSteps > allowedSteps) {
                pipeline.addError(Label.BRANCH_MGMT_LICENSE_EXCEEDED);     
            }
        }
    }

    private Integer existingSteps() {
        // Note: exclude scratch orgs from used CBM licenses

        return [SELECT count() FROM Deployment_Flow_Step__c 
                    WHERE Deployment_Flow__r.Active__c = true 
                        AND Deployment_Flow__r.Main_Branch__c != null 
                        AND Deployment_Flow__r.Git_Repository__c != null 
                        AND (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') 
                        AND Branch__c != null];
    }

    private Integer newSteps() {
        Integer result = 0;

        for(Deployment_Flow__c pipeline : pipelines){
            if(Trigger.isInsert) {
                result++;
            }
        }

        return result;
    }

    private List<Deployment_Flow__c> filterValid(List<Deployment_Flow__c> pipelines) {
        List<Deployment_Flow__c> result = new List<Deployment_Flow__c>();

        for(Deployment_Flow__c pipeline : pipelines) {
            if(isValid(pipeline)) {
                result.add(pipeline);
            }
        }

        return result;
    }

    private Boolean isValid(Deployment_Flow__c pipeline) {
        return (pipeline.Active__c == true && pipeline.Git_Repository__c != null && String.isNotBlank(pipeline.Main_branch__c));
    }
}