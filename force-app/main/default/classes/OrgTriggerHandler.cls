public with sharing class OrgTriggerHandler implements ITrigger {
    public OrgTriggerHandler() {
    }

    public void bulkBefore() {
        if (Trigger.isUpdate)
            OrgTriggerHelper.prepareData(Trigger.New);
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        OrgTriggerHelper.checkApexTest((Org__c) so);
        OrgTriggerHelper.setOrgEnvironment((Org__c) so);

        Org__c oldOrgRecord = (Org__c) oldSo;
        Org__c newOrgRecord = (Org__c) so;
        if (newOrgRecord.Default_Credential__c && !oldOrgRecord.Default_Credential__c) {
            OrgTriggerHelper.verifyDefaultCredExist(Trigger.New);
        }
    }
    
    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        OrgTriggerHelper.isScheduled((Org__c) so);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        OrgTriggerHelper.isScheduled((Org__c) so);
        OrgTriggerHelper.isMetadataChanged((Org__c) so, (Org__c) oldSo);
    }

    public void afterDelete(SObject so) {
    }

    public void afterUndelete(SObject so) {
    }
    public void andFinally() {
        OrgTriggerHelper.enforceScheduler();
        OrgTriggerHelper.deleteMetadataAttachments();
    }
}