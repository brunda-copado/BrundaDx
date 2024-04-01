public with sharing class AutomationRuleFilterCriteriaCtrl {
    @AuraEnabled
    public static SyntaxResponse checkSyntax(String objectName, String whereCondition) {
        SyntaxResponse result = new SyntaxResponse();
        try {
            String query = 'SELECT Id FROM {0} WHERE {1}';
            Database.query(String.format(query, new List<String>{ objectName, whereCondition }));
            result.isValid = true;
        } catch (QueryException e) {
            result.isValid = false;
            result.message = e.getMessage();
        }
        return result;
    }

    public with sharing class SyntaxResponse {
        @AuraEnabled
        public Boolean isValid;
        @AuraEnabled
        public String message;
    }
}