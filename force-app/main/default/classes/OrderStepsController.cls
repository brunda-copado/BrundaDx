public with sharing class OrderStepsController {
    @AuraEnabled(cacheable=false)
    public static List<JobStep__c> getSteps(Id parentId) {
        try {
            return new JobStepsSelector().byParent(parentId);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void saveSteps(List<JobStep__c> records) {
        try {
            update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}