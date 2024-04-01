public with sharing class ComplianceRuleLogicValidator {
    private String criteriaLogic;
    private List<Compliance_Rule_Criteria__c> criterias;

    // CONSTRUCTOR

    public ComplianceRuleLogicValidator(String criteriaLogic, List<Compliance_Rule_Criteria__c> criterias) {
        this.criteriaLogic = criteriaLogic.toUpperCase();
        this.criterias = criterias;
    }

    // PUBLIC

    public ValidationResult execute() {
        ValidationResult result = new ValidationResult();

        if (isSyntaxInvalid(criteriaLogic)) {
            result.addError(Label.CCH_NONVALID_CRITERIA_LOGIC_SYNTAX);
        } else if (criteriaRowsMismatch(criteriaLogic, criterias)) {
            result.addError(Label.CCH_NONVALID_CRITERIA_LOGIC_REFERENCES);
        }

        return result;
    }

    // PRIVATE

    private Boolean isSyntaxValid(String logic) {
        return (bracketsAreClosed(logic) && criteriaReferencesAreNumeric(logic));
    }

    private Boolean isSyntaxInvalid(String logic) {
        return !isSyntaxValid(logic);
    }

    private Boolean bracketsAreClosed(String criteriaLogic) {
        return criteriaLogic.countMatches('(') == criteriaLogic.countMatches(')');
    }

    private Boolean criteriaReferencesAreNumeric(String criteriaLogic) {
        Boolean result = true;

        for (String criteriaRef : criteraRefsFrom(criteriaLogic)) {
            if (!criteriaRef.isNumeric()) {
                result = false;
                break;
            }
        }

        return result;
    }

    private Boolean criteriaRowsMismatch(String criteriaLogic, List<Compliance_Rule_Criteria__c> criterias) {
        List<String> criteriaRefs = criteraRefsFrom(criteriaLogic);

        Boolean sizeMismatch = criteriaRefs.size() != criterias.size();

        Boolean referenceMismatch = false;
        for (Compliance_Rule_Criteria__c criteria : criterias) {
            if (!criteriaRefs.contains(String.valueOf(criteria.Order__c))) {
                referenceMismatch = true;
                break;
            }
        }

        return (sizeMismatch || referenceMismatch);
    }

    private List<String> criteraRefsFrom(String criteriaLogic) {
        List<String> result = new List<String>();

        for (String criteriaRow : criteriaLogic.split(' AND | OR ')) {
            result.add(criteriaRow.trim().replaceAll('\\)', '').replaceAll('\\(', ''));
        }

        return result;
    }
}