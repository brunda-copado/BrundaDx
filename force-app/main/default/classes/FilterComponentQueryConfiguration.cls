public with sharing class FilterComponentQueryConfiguration {
    @AuraEnabled public String fieldSelected;
    @AuraEnabled public String operatorUsed;
    @AuraEnabled public String fieldValue;
    @AuraEnabled public String[] fieldSelectedValues;
    @AuraEnabled public String fieldLabelSelected;
    @AuraEnabled public String operatorLabelSelected;
    @AuraEnabled public Boolean isEmpty;
    @AuraEnabled public String fieldTypeSelected;
    @AuraEnabled public String id;
   
    // PUBLIC 

    public string getWhereClause(){
        if (FilterConstant.isNonStringOperator(fieldTypeSelected)) {
            return getNonStringClause();
        } else {
            return getStringClause() ; 
        }
    }

    // PRIVATE
    
    private string getNonStringClause(){
        fieldValue = String.escapeSingleQuotes(fieldValue);
        fieldSelected = String.escapeSingleQuotes(fieldSelected);
        operatorUsed = String.escapeSingleQuotes(operatorUsed);
        Boolean isDoubleTypeField = fieldTypeSelected==FilterConstant.FIELDTYPE_DOUBLE;
        Boolean isBooleanTypeField = fieldTypeSelected==FilterConstant.FIELDTYPE_BOOLEAN;
        if (isDoubleTypeField) {
            handleDoubleClause();
        } else if (isBooleanTypeField) {
            handleBooleanClause();
        }
        return FilterConstant.getFormattedNonStringClause(fieldSelected, fieldValue, operatorUsed);
    }

    private void handleDoubleClause() {
        if (FilterConstant.isStringSpecificOperator(operatorUsed)) {
            operatorUsed = FilterConstant.handleStringOperatorForDouble(operatorUsed);
        } else {
            handleInvalidDoubleValues();
        }
    }

    private void handleInvalidDoubleValues() {
        if (FilterConstant.isInvalidDoubleValue(fieldValue)) {
            fieldValue = FilterConstant.INVALID_STRING;
        } else if (FilterConstant.isBlankDoubleValue(fieldValue)) {
            handleBlankDoubleValue();
        }
    }

    private void handleBooleanClause() {
        operatorUsed = FilterConstant.getBooleanOperator(operatorLabelSelected);
    }

    private string getStringClause(){
        fieldValue =fieldValue==null?'': String.escapeSingleQuotes(fieldValue);
        fieldSelected = String.escapeSingleQuotes(fieldSelected);
        operatorUsed = String.escapeSingleQuotes(operatorUsed);

        String clause = FilterConstant.getFormattedStringClause(fieldSelected, fieldValue, operatorUsed);
        Boolean isPicklistField = fieldTypeSelected==FilterConstant.FIELDTYPE_PICKLIST;

        if (!isPicklistField && FilterConstant.isStringSpecificOperator(operatorUsed)) {
            clause = getStringSpecificClause(clause);
        } else if (isPicklistField) {
            clause = getMultiselectClause();
        }
        return clause;
    }

    private void handleBlankDoubleValue() {
        Boolean isEqualOperator = operatorUsed == FilterConstant.OPERATOR_EQUAL;
        
        if (isEqualOperator) {
            fieldValue = null;                 
        }
        else {
            fieldValue = null;  
            operatorUsed = FilterConstant.OPERATOR_NOT_EQUAL;            
        }
    }

    private string getStringSpecificClause(String clause){
        Boolean hasFieldValue = String.isNotBlank(fieldValue);
        return hasFieldValue ? FilterConstant.getNonBlankStringSpecificClause(fieldSelected, fieldValue, operatorUsed) : getBlankStringClause();        
    }

    private String getBlankStringClause() {
        return fieldSelected + ' ' + FilterConstant.OPERATOR_NOT_EQUAL + '\'' + fieldValue + '\'';
    }

    private string getMultiselectClause(){
        fieldSelectedValues = FilterConstant.getFieldSelectedValues(fieldSelectedValues);
        return createMultiSelectClause();
    }

    private string createMultiSelectClause(){
        FilterConstant.OPERATOR_TYPES operator = FilterConstant.OPERATOR_TYPES_BY_STRING.get(operatorLabelSelected.deleteWhitespace().toUppercase());
        String clause = '';
        switch on operator {
            when EQUAL {    
                clause = fieldSelected+' IN '+ FilterConstant.getConcatenatedString(fieldSelectedValues) ;
            }
            when NOTEQUAL {     
                clause = fieldSelected+' NOT IN '+ FilterConstant.getConcatenatedString(fieldSelectedValues) ;
            }
            when LESSTHAN {
                clause = getClausesWithORCondition();
            }
            when GREATERTHAN {  
                clause = getClausesWithORCondition();
            }
            when LESSTHANOREQUAL {  
                clause = getClausesWithORCondition();
            }
            when GREATERTHANOREQUAL {
                clause = getClausesWithORCondition();
            }
            when CONTAINS { 
                clause = getClausesForLikeConditionWithOR();
            }
            when DOESNOTCONTAINS {
                clause = getClausesForLikeConditionWithAnd();
            }
            when STARTSWITH {
                clause = getClausesForStartsWithConditionWithOR();
            } 
        }
        return clause;
    }
    
    private String getClausesWithORCondition(){
        return handleNonEmptyPicklistClause(' OR ');
    }

    private String getClausesForLikeConditionWithOR(){
        return FilterConstant.isEmptyValues(fieldSelectedValues) ? handleEmptyPicklistClause() : handleNonEmptyPicklistClause(' OR ');
    }

    private String getClausesForLikeConditionWithAnd(){
        return FilterConstant.isEmptyValues(fieldSelectedValues) ? handleEmptyPicklistClause() : handleNonEmptyPicklistClause(' AND ');
    }
   
    private String getClausesForStartsWithConditionWithOR(){
        return FilterConstant.isEmptyValues(fieldSelectedValues) ? handleEmptyPicklistClause() : handleNonEmptyPicklistClause(' OR ');
    }

    private String handleEmptyPicklistClause() {
        return '(' + fieldSelected + ' ' + FilterConstant.OPERATOR_NOT_EQUAL + '\'\'' + ')';
    }

    private String handleNonEmptyPicklistClause(String logicalOperator) {
        return iteratePicklistValues(logicalOperator);
    }

    private String iteratePicklistValues(String logicalOperator) {
        String clause = '';
        for(String value :fieldSelectedValues){
            value = String.escapeSingleQuotes(value);
            clause = getPicklistValueClause(clause, logicalOperator, value);
        }
        return FilterConstant.formatPicklistClause(clause);
    }

    private String getPicklistValueClause (String clause, String logicalOperator, String value) {
        String formattedClause = getFormattedPicklistValueClause(value);
        return String.isBlank(clause) ? formattedClause : clause + logicalOperator + formattedClause;
    }

    private String getFormattedPicklistValueClause (String value) {
        return FilterConstant.isStringSpecificOperator(operatorUsed) ? FilterConstant.getNonBlankStringSpecificClause(fieldSelected, value, operatorUsed) : FilterConstant.getFormattedStringClause(fieldSelected, value, operatorUsed);   
    }
}