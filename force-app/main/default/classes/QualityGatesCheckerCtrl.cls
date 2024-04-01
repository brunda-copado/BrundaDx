public with sharing class QualityGatesCheckerCtrl {
    private static final String STATUS_INACTIVE = 'Inactive';
    private static final String STATUS_ACTIVE = 'Active';

    @AuraEnabled(cacheable=false)
    public static QualityGatesCheckResult checkQualityGates(Id recordId) {
        QualityGatesCheckResult result = new QualityGatesCheckResult();

        result.hasPermission =
            Utilities.checkPermission('Configure_AQF', new Set<Id>{ UserInfo.getUserId() }) &&
            Utilities.checkPermission('Configure_Automations', new Set<Id>{ UserInfo.getUserId() });

        if (!result.hasPermission) {
            return result;
        }

        String objectName = objectName(recordId);

        String pipelineId;
        String platform;
        if (objectName == Schema.SObjectType.Promotion__c.getName()) {
            Promotion__c promotion = getPromotion(recordId);
            pipelineId = new FindPipeline().fromObject(promotion);
            platform = promotion.Platform__c;
        } else if (objectName == Schema.SObjectType.User_Story__c.getName()) {
            User_Story__c userStory = getUserStory(recordId);
            pipelineId = new FindPipeline().fromObject(userStory);
            platform = userStory.Platform__c;
        }
        result.qualityGateRules = getQualityGateRulesWithoutAutomationRule(platform, pipelineId);

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static void deactivateQualityGates(List<Quality_Gate_Rule__c> qualityGateRules) {
        List<Quality_Gate_Rule__c> qualityGateRulesToUpdate = new List<Quality_Gate_Rule__c>();
        for (Quality_Gate_Rule__c qualityGateRule : qualityGateRules) {
            qualityGateRulesToUpdate.add(new Quality_Gate_Rule__c(Id = qualityGateRule.Id, Status__c = STATUS_INACTIVE));
        }
        DML.safeUpdate(
            qualityGateRulesToUpdate,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    Quality_Gate_Rule__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFAULT).getLabel(),
                    'QualityGatesCheckerCtrl.deactivateQualityGates'
                }
            )
        );
    }

    @AuraEnabled(cacheable=false)
    public static void activateQualityGates(List<Quality_Gate_Rule__c> qualityGateRules) {
        List<Quality_Gate_Rule__c> qualityGateRulesToUpdate = new List<Quality_Gate_Rule__c>();
        for (Quality_Gate_Rule__c qualityGateRule : qualityGateRules) {
            qualityGateRulesToUpdate.add(new Quality_Gate_Rule__c(Id = qualityGateRule.Id, Status__c = STATUS_ACTIVE));
        }
        DML.safeUpdate(
            qualityGateRulesToUpdate,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    Quality_Gate_Rule__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFAULT).getLabel(),
                    'QualityGatesCheckerCtrl.activateQualityGates'
                }
            )
        );
    }

    // PRIVATE

    private static String objectName(Id recordId) {
        return recordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFAULT).getName();
    }

    private static User_Story__c getUserStory(String recordId) {
        return [
            SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Platform__c
            FROM User_Story__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private static Promotion__c getPromotion(String recordId) {
        return [
            SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Platform__c
            FROM Promotion__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private static List<Quality_Gate_Rule__c> getQualityGateRulesWithoutAutomationRule(String platform, String pipelineId) {
        Set<Id> qualityRulesUsingAutomationRule = new Set<Id>();
        for (Automation_Rule__c automationRule : [
            SELECT Quality_Gate_Rule_Condition__r.Quality_Gate_Rule__c
            FROM Automation_Rule__c
            WHERE Quality_Gate_Rule_Condition__c != NULL
            WITH USER_MODE
        ]) {
            qualityRulesUsingAutomationRule.add(automationRule.Quality_Gate_Rule_Condition__r.Quality_Gate_Rule__c);
        }

        return [
            SELECT Id
            FROM Quality_Gate_Rule__c
            WHERE
                Status__c = :STATUS_ACTIVE
                AND Execution_sequence__c = 'After'
                AND Id IN (SELECT Quality_Gate_Rule__c FROM Quality_Gate_Rule_Condition__c WHERE Pipeline__c = :pipelineId OR Platform__c = :platform)
                AND Id NOT IN :qualityRulesUsingAutomationRule
            WITH USER_MODE
        ];
    }

    public with sharing class QualityGatesCheckResult {
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Boolean hasPermission;
        @AuraEnabled
        public List<Quality_Gate_Rule__c> qualityGateRules = new List<Quality_Gate_Rule__c>();
    }
}