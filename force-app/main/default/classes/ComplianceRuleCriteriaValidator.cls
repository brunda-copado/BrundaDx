public with sharing class ComplianceRuleCriteriaValidator {
    private List<Compliance_Rule_Criteria__c> criterias;

    // CONSTRUCTOR

    public ComplianceRuleCriteriaValidator(List<Compliance_Rule_Criteria__c> criterias) {
        this.criterias = criterias;
    }

    // PUBLIC

    public ValidationResult execute() {
        ValidationResult result = new ValidationResult();

        if (criterias.isEmpty()) {
            result.addError(Label.AT_LEAST_ONE_VALID_CRITERIA);
        } else {
            for (Compliance_Rule_Criteria__c criteria : criterias) {
                if (isIncomplete(criteria)) {
                    result.addError(String.format(Label.CCH_NONVALID_CRITERIA, new List<String>{ String.valueOf(criteria.Order__c) }));
                }
            }

            if (duplicatedCriteriaIn(criterias)) {
                result.addError(Label.CCH_DUPLICATED_CRITERIA);
            }
        }

        return result;
    }

    // PRIVATE

    private Boolean isIncomplete(Compliance_Rule_Criteria__c criteria) {
        return (String.isBlank(criteria.Node__c) ||
            String.isBlank(criteria.Field__c) ||
            String.isBlank(criteria.Operator__c) ||
            String.isBlank(criteria.Value__c));
    }

    private Boolean duplicatedCriteriaIn(List<Compliance_Rule_Criteria__c> criterias) {
        Boolean result = false;

        Set<Compliance_Rule_Criteria__c> criteriaSet = new Set<Compliance_Rule_Criteria__c>();
        for (Compliance_Rule_Criteria__c criteria : criterias) {
            Compliance_Rule_Criteria__c criteriaCopy = new Compliance_Rule_Criteria__c();

            criteriaCopy.Node__c = criteria.Node__c;
            criteriaCopy.Field__c = criteria.Field__c;
            criteriaCopy.Operator__c = criteria.Operator__c;
            criteriaCopy.Value__c = criteria.Value__c;

            criteriaSet.add(criteriaCopy);
        }

        if (criterias.size() != criteriaSet.size()) {
            result = true;
        }

        return result;
    }
}