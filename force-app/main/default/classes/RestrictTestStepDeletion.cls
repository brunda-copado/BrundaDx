public with sharing class RestrictTestStepDeletion {
    private List<JobStep__c> records;

    // CONSTRUCTOR

    public RestrictTestStepDeletion(List<JobStep__c> records) {
        this.records = records;
    }

    // PUBLIC

    public void run() {
        if (hasPermission()) {
            return;
        }

        for (JobStep__c record : records) {
            if (record.Type__c == 'Test') {
                record.addError(Label.Delete_Test_Step_Forbidden);
            }
        }
    }

    // PRIVATE

    private Boolean hasPermission() {
        return FeatureManagement.checkPermission('Delete_Test_Job_Steps');
    }
}