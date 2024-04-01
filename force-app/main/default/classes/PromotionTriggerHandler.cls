@SuppressWarnings('PMD.EmptyStatementBlock')
public with sharing class PromotionTriggerHandler implements ITrigger {
    public class ApplicationException extends Exception {
    }

    public PromotionTriggerHandler() {
    }

    public void bulkBefore() {
        if (!PromotionTriggerHelper.bypassPromotionTrigger) {
            if (Trigger.isInsert || Trigger.isUpdate) {
                PromotionTriggerHelper.prepareData(Trigger.new, Trigger.old);
            }
        }
    }

    public void bulkAfter() {
    }

    public void beforeCommon(SObject so) {
        if (!PromotionTriggerHelper.bypassPromotionTrigger) {
            //prevent any DML for non Copado enabled users or non CCM enabled users || flow is inactive || flow is not valid CBM && user is CCM only
            PromotionTriggerHelper.canPromoteThis((Promotion__c) so);
        }
    }

    public void beforeInsert(SObject so) {
        if (!PromotionTriggerHelper.bypassPromotionTrigger) {
            PromotionTriggerHelper.setDestinationOrgFromFlow((Promotion__c) so);
            if (PromotionTriggerHelper.hasEqualDeploymentFlows((Promotion__c) so)) {
                beforeCommon(so);
                PromotionTriggerHelper.setSourceOrgFromEnvironment((Promotion__c) so);
                PromotionTriggerHelper.validateOrgEnvironmentRelationship((Promotion__c) so);
                PromotionTriggerHelper.setAutoResolveConflictOption((Promotion__c) so);
            }
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        if (!PromotionTriggerHelper.bypassPromotionTrigger) {
            PromotionTriggerHelper.setDestinationOrgFromFlow((Promotion__c) so);
            if (PromotionTriggerHelper.hasEqualDeploymentFlows((Promotion__c) so)) {
                beforeCommon(so);
                PromotionTriggerHelper.setSourceOrgFromEnvironment((Promotion__c) so);
                PromotionTriggerHelper.validateOrgEnvironmentRelationship((Promotion__c) so);
                PromotionTriggerHelper.setMergeConflictField((Promotion__c) so);
                PromotionTriggerHelper.syncCompletedForMultiCloud((Promotion__c) oldSo, (Promotion__c) so);
            }
        }
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        if (!PromotionTriggerHelper.bypassPromotionTrigger) {
            PromotionTriggerHelper.separateMulticloudPromotions((Promotion__c) so);
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        if (!PromotionTriggerHelper.bypassPromotionTrigger) {
            PromotionTriggerHelper.isCompleted((Promotion__c) so, (Promotion__c) oldSo);
            PromotionTriggerHelper.accumulateIfCompleted((Promotion__c) so, (Promotion__c) oldSo);
            PromotionTriggerHelper.markUserStoryMetadataBackPromoted((Promotion__c) so);
        }
    }

    public void afterDelete(SObject so) {
    }

    public void afterUndelete(SObject so) {
    }

    public void andFinally() {
        if (!PromotionTriggerHelper.bypassPromotionTrigger) {
            if (Trigger.isInsert || Trigger.isUpdate) {
                PromotionTriggerHelper.accumulateCompletedListIfNotEmpty();
                PromotionTriggerHelper.resetUserStories();
                PromotionTriggerHelper.runSeleniumTestGroups();
                PromotionTriggerHelper.updateUserStoryMetadatasBackPromoted();
            }
            if (Trigger.isAfter && Trigger.isUpdate) {
                PromotionTriggerHelper.promoteBundleChildStories();
            }
        }
    }
}