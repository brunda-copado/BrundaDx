public with sharing class ActivateQualityGateRuleCtrl {
    @AuraEnabled
    public static ActivationResult activate(Id qualityGateRuleId) {
        try {
            ActivationResult result = new ActivationResult();
            if (ruleHasConditions(qualityGateRuleId)) {
                activateQualityGateRule(qualityGateRuleId);
                result.activated = true;
            } else {
                result.message = Label.QualityGateRuleActivationNoConditions;
            }
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Boolean ruleHasConditions(Id qualityGateRuleId) {
        return !new QualityGateRuleConditionsSelector().byQualityGateRule(qualityGateRuleId).isEmpty();
    }

    private static void activateQualityGateRule(Id qualityGateRuleId) {
        update Security.stripInaccessible(AccessType.UPDATABLE, new List<Quality_Gate_Rule__c>{ new Quality_Gate_Rule__c(Id = qualityGateRuleId, Status__c = 'Active') }).getRecords();
    }

    public with sharing class ActivationResult {
        @AuraEnabled
        public Boolean activated;
        @AuraEnabled
        public String message;

        public ActivationResult() {
            this.activated = false;
            this.message = '';
        }
    }
}