public with sharing class ComplianceRuleManagerCtrl {
    // PUBLIC

    @AuraEnabled
    public static String getComplianceFileFromBackend() {
        try {
            return (String) new HerokuCallout(Settings.server_url + '/json/v1/complianceMetadata', HttpMethod.GET)
                .default()
                .request()
                .response()
                .getBody();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void deleteCriterias(List<Compliance_Rule_Criteria__c> criterias) {
        try {
            Utilities.Secure_DML(criterias, Utilities.DML_Action.DEL, Schema.SObjectType.Compliance_Rule_Criteria__c);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void saveCriterias(List<Compliance_Rule_Criteria__c> criteria, String criteriaLogic, String metadataType) {
        try {
            if (!criteria.isEmpty()) {
                Utilities.Secure_DML(criteria, Utilities.DML_Action.UPS, Schema.SObjectType.Compliance_Rule_Criteria__c);

                Id ruleId = criteria.get(0).Compliance_Rule__c;

                Compliance_Rule__c rule = new ComplianceRulesSelector().byId(new Set<Id>{ ruleId }).get(0);
                rule.Metadata_Type__c = metadataType;
                rule.Filter_Criteria__c = parseLogic(criteriaLogic, ruleId);
                rule.Is_Valid__c = true;
                // @TODO: To be removed when backend deletes it
                rule.Record_Count_Criteria__c = 'Number of groups';
                rule.Matching_Criteria__c = 'Greater or Equal';
                rule.Record_Count__c = 1;

                Utilities.Secure_DML(rule, Utilities.DML_Action.UPD, Schema.SObjectType.Compliance_Rule__c);
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<Compliance_Rule_Criteria__c> criteriasOfRule(Id ruleId) {
        try {
            return new ComplianceRuleCriteriaSelector().byComplianceRuleId(new Set<Id>{ ruleId });
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static String validatePermissions() {
        try {
            return new ComplianceRulePermissionsValidator().execute().toString();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void validateCriterias(List<Compliance_Rule_Criteria__c> criterias, String criteriaLogic) {
        ValidationResult criteriasValidation = new ComplianceRuleCriteriaValidator(criterias).execute();
        if (criteriasValidation.isError()) {
            new ApplicationException(criteriasValidation).throwAuraHandled();
        }

        ValidationResult logicValidation = new ComplianceRuleLogicValidator(criteriaLogic, criterias).execute();
        if (logicValidation.isError()) {
            new ApplicationException(logicValidation).throwAuraHandled();
        }
    }

    // PRIVATE

    private static String parseLogic(String criteriaLogic, Id ruleId) {
        String result = criteriaLogic;

        Integer criteriaCount = criteriaLogic.split('AND|OR').size();
        Map<Integer, Compliance_Rule_Criteria__c> criteriaByOrder = getCriteriaByOrder(criteriasOfRule(ruleId));

        // Note: We first need to enclose the criteria reference within <>, in order that it is not later replaced in the same loop if there are more than 10 criterias
        for (Integer i = 1; i <= criteriaCount; i++) {
            result = result.replaceFirst(String.valueOf(i), '<' + String.valueOf(i) + '>');
        }

        // Note: We replace enclosed criteria references to criteria order by the criteria name
        for (Integer i = 1; i <= criteriaCount; i++) {
            result = result.replaceFirst('<' + String.valueOf(i) + '>', criteriaByOrder.get(i).Name);
        }

        return result;
    }

    private static Map<Integer, Compliance_Rule_Criteria__c> getCriteriaByOrder(List<Compliance_Rule_Criteria__c> criterias) {
        Map<Integer, Compliance_Rule_Criteria__c> result = new Map<Integer, Compliance_Rule_Criteria__c>();

        for (Compliance_Rule_Criteria__c criteria : criterias) {
            result.put((Integer) criteria.Order__c, criteria);
        }

        return result;
    }
}