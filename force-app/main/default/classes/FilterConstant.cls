public with sharing class FilterConstant {

    // CONSTANTS 
    
    private static final String NON_STRING_TEMPLATE = '{0} {1} {2}';
    private static final String STRING_TEMPLATE = '{0} {1} \'\'{2}\'\'';
    private static final String LIKE_OPERATOR_TEMPLATE = '{0} LIKE \'\'%{1}%\'\'';
    private static final String NOT_LIKE_OPERATOR_TEMPLATE = '(NOT {0} LIKE \'\'%{1}%\'\')';
    private static final String STARTS_WITH_OPERATOR_TEMPLATE = '{0} LIKE \'\'{1}%\'\'';

    // PUBLIC

    public enum OPERATOR_TYPES {
        EQUAL,
        NOTEQUAL,
        LESSTHAN, 
        GREATERTHAN, 
        LESSTHANOREQUAL, 
        GREATERTHANOREQUAL, 
        CONTAINS, 
        DOESNOTCONTAINS,
        STARTSWITH
    }

    public static final String USER_STORY='User_Story__c';
    public static final String FIELDTYPE_BOOLEAN = 'BOOLEAN';
    public static final String FIELDTYPE_DOUBLE = 'DOUBLE';
    public static final String FIELDTYPE_PICKLIST = 'PICKLIST';
    public static final String OPERATOR_LIKE = 'Like';
    public static final String OPERATOR_NOT_LIKE = 'NotLike';
    public static final String OPERATOR_NOT_EQUAL = '!=';
    public static final String OPERATOR_LESS_THAN = '<';
    public static final String OPERATOR_LESS_THAN_EQUAL = '<=';
    public static final String OPERATOR_EQUAL = '=';
    public static final String OPERATOR_STARTS_WITH = 'StartsWith';
    public static final String OWNER_STRING = 'My User Stories';
    public static final String INVALID_STRING = '-1000';

    public static final Map<String, OPERATOR_TYPES> OPERATOR_TYPES_BY_STRING = new Map<String, OPERATOR_TYPES>();
    static {
        for(OPERATOR_TYPES value : OPERATOR_TYPES.values()){
            OPERATOR_TYPES_BY_STRING.put(value.name(), value);
        }
    }

    public static Boolean isInvalidDoubleValue(String fieldValue) {
        return String.isNotBlank(fieldValue) && !fieldValue.isNumericspace();
    }

    public static Boolean isBlankDoubleValue(String fieldValue) {
        return String.isBlank(fieldValue);
    }

    public static Boolean isNonStringOperator(String fieldTypeSelected) {
        return fieldTypeSelected == FIELDTYPE_BOOLEAN || fieldTypeSelected==FIELDTYPE_DOUBLE;
    }

    public static Boolean isStringSpecificOperator(String operatorUsed) {
        return isLikeStringOperator(operatorUsed) || isNotLikeStringOperator(operatorUsed) || isStartsWithStringOperator(operatorUsed);
    }

    public static String getFormattedNonStringClause(String fieldSelected, String value, String operatorUsed) {
        return String.format(NON_STRING_TEMPLATE, getClauseParameters(fieldSelected, value, operatorUsed));
    }

    public static String getFormattedStringClause(String fieldSelected, String value, String operatorUsed) {
        return String.format(STRING_TEMPLATE, getClauseParameters(fieldSelected, value, operatorUsed));
    }

    public static String getConcatenatedString(String[] fieldSelectedValues){
        String arrAsValue = '';
        for(String value :fieldSelectedValues){
            value = String.escapeSingleQuotes(value);
            arrAsValue = getFormattedStringValue(arrAsValue, value);
        }
        return '('+arrAsValue +')';
    }

    public static List<String> getFieldSelectedValues(String[] fieldSelectedValues){
         return (fieldSelectedValues == null || fieldSelectedValues.size() == 0) ? new List<String>{''} : fieldSelectedValues;
    }

    public static Boolean isEmptyValues(List<String> fieldSelectedValues) {
        return fieldSelectedValues.size() == 1 && fieldSelectedValues[0].length() == 0;
    }

    public static String getNonBlankStringSpecificClause(String fieldSelected, String value, String operator) {
        String clause = '';
        switch on operator {
            when 'Like' {   
                clause = getFormattedLikeClause(fieldSelected, value);
            }
            when 'NotLike' {        
                clause = getFormattedNotLikeClause(fieldSelected, value);
            }
            when 'StartsWith' {
                clause = getFormattedStartsWithClause(fieldSelected, value);
            }
        }
        return clause;
    }

    public static Boolean isBooleanWithEqualOperator(String operatorLabelSelected) {
        Boolean result = false;
        OPERATOR_TYPES operator = OPERATOR_TYPES_BY_STRING.get(operatorLabelSelected.deleteWhitespace().toUppercase());
        switch on operator {
            when EQUAL {    
                result = true;
            }
            when LESSTHANOREQUAL {  
                result = true;
            }
            when GREATERTHANOREQUAL {
                result = true;
            }
            when CONTAINS { 
                result = true;
            }
            when STARTSWITH {
                result = true;
            } 
        }
        return result;
    }

    public static Boolean isBooleanWithNotEqualOperator(String operatorLabelSelected) {
        Boolean result = false;
        OPERATOR_TYPES operator = OPERATOR_TYPES_BY_STRING.get(operatorLabelSelected.deleteWhitespace().toUppercase());
        switch on operator {
            when NOTEQUAL {     
                result = true;
            }
            when LESSTHAN {
                result = true;
            }
            when GREATERTHAN {  
                result = true;
            }
            when DOESNOTCONTAINS {
                result = true;
            }
        }
        return result;
    }

    public static String handleStringOperatorForDouble(String operator) {
        String operatorUsed = '';
        switch on operator {
            when 'Like' {   
                operatorUsed = OPERATOR_EQUAL;
            }
            when 'NotLike' {        
                operatorUsed = OPERATOR_NOT_EQUAL;
            }
            when 'StartsWith' {
                operatorUsed = OPERATOR_EQUAL;
            }
        }
        return operatorUsed;
    }

    public static String formatPicklistClause(String clause) {
        return String.isNotBlank(clause) ? '('+clause +')' : '';
    }

    public static String getBooleanOperator(String operatorLabelSelected) {
        String operatorUsed = '';
        if (FilterConstant.isBooleanWithEqualOperator(operatorLabelSelected)) {
            operatorUsed = FilterConstant.OPERATOR_EQUAL;
        } else if (FilterConstant.isBooleanWithNotEqualOperator(operatorLabelSelected)) {
            operatorUsed = FilterConstant.OPERATOR_NOT_EQUAL;
        }
        return operatorUsed;
    }

    // PRIVATE 

    private static Boolean isLikeStringOperator(String operatorUsed) {
        return operatorUsed == OPERATOR_LIKE;
    }

    private static Boolean isNotLikeStringOperator(String operatorUsed) {
        return operatorUsed == OPERATOR_NOT_LIKE;
    }

    private static Boolean isStartsWithStringOperator(String operatorUsed) {
        return operatorUsed == OPERATOR_STARTS_WITH;
    }

    private static List<Object> getClauseParameters(String fieldSelected, String value) {
        return new List<Object> {fieldSelected, value};
    }

    private static List<Object> getClauseParameters(String fieldSelected, String value, String operatorUsed) {
        return new List<Object> {fieldSelected, operatorUsed, value};
    }

    private static String getFormattedStringValue (String arrAsValue, String value) {
        String formattedValue = '\'' + value + '\'';
        return String.isBlank(arrAsValue) ? formattedValue : arrAsValue + ',' + formattedValue;
    }

    private static String getFormattedLikeClause(String fieldSelected, String value) {
        return String.format(LIKE_OPERATOR_TEMPLATE, getClauseParameters(fieldSelected, value));
    }

    private static String getFormattedNotLikeClause(String fieldSelected, String value) {
        return String.format(NOT_LIKE_OPERATOR_TEMPLATE, getClauseParameters(fieldSelected, value));
    }

    private static String getFormattedStartsWithClause(String fieldSelected, String value) {
        return String.format(STARTS_WITH_OPERATOR_TEMPLATE, getClauseParameters(fieldSelected, value));
    }
}