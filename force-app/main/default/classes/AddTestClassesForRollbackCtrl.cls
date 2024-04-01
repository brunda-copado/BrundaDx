public with sharing class AddTestClassesForRollbackCtrl {
    public Id destinationOrgId { get; set; }
    public Step__c step { get; set; }
    public AddTestClassesForRollbackCtrl(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(Utilities.getAllFields('Step__c').get(Label.FIELDS).split(','));
        }
        this.step = (Step__c) stdController.getRecord();
        this.destinationOrgId = Utilities.getDestinationOrgsByDeploymentId(this.step.Deployment__c)[0].To_Org__c;
    }
}