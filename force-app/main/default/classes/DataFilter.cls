public inherited sharing class DataFilter {
    @AuraEnabled
    public Integer order { get; set; }
    @AuraEnabled
    public String fieldName { get; set; }
    @AuraEnabled
    public String fieldLabel { get; set; }
    @AuraEnabled
    public String fieldType { get; set; }
    @AuraEnabled
    public String operatorCode { get; set; }
    @AuraEnabled
    public String value { get; set; }

    public DataFilter() {
    }

    public DataFilter(QueryEditor.CriteriaWrapper criteria) {
        this.order = criteria.order;
        this.fieldName = criteria.fieldName.indexOf('-') != -1 ? criteria.fieldName.substringAfterLast('-') : criteria.fieldName;
        this.fieldLabel = criteria.fieldLabel;
        this.fieldType = criteria.fieldType;
        this.operatorCode = criteria.operator;
        this.value = parseValue(criteria);
    }

    public QueryEditor.CriteriaWrapper toQueryCriteria() {
        QueryEditor.CriteriaWrapper result = new QueryEditor.CriteriaWrapper();
        // only order and final value are required by the backend
        result.order = this.order;
        result.finalValue = getWhereCondition();
        result.fieldName = this.fieldLabel + '-' + this.fieldName;
        result.fieldLabel = this.fieldLabel;
        result.fieldType = this.fieldType;
        result.operator = this.operatorCode;
        result.operatorSet = null;
        result = setFilterInputs(result);
        return result;
    }

    public String getWhereCondition() {
        String result;

        if (isCustomFilter(this.fieldName)) {
            result = this.value;
        } else {
            String operator = this.operatorCode;
            String value = this.value != null ? String.escapeSingleQuotes(this.value) : '';
            switch on operator {
                when 's' {
                    value += '%';
                }
                when 'c', 'k' {
                    value = '%' + value + '%';
                }
            }

            if (isStringLiteral()) {
                value = '\'' + value + '\'';
            }

            if (!isStringLiteral() && String.isBlank(value)) {
                value = NULL_VALUE;
            }

            Map<String, String> symbolsByOperators = OperatorTypeCodes.getOperatorSembols();
            String symbol = symbolsByOperators.get(operator);

            result = fieldName + symbol + value;

            if (operator == 'k') {
                result = ' (NOT ' + result + ') ';
            }
        }

        return result;
    }

    private Boolean isStringLiteral() {
        return !isNumber(this.fieldType) && !isBoolean(this.fieldType) && !isDate(this.fieldType) && !isDatetime(this.fieldType);
    }

    private String parseValue(QueryEditor.CriteriaWrapper criteria) {
        String result = criteria.input;
        if (isDate(criteria.fieldType) || isDatetime(criteria.fieldType)) {
            String dateOption = String.isNotBlank(criteria.input) ? criteria.input.trim() : null;
            if (dateOption != null) {
            Matcher optionMatcher = DATE_RANGE_OPTION_PATTERN.matcher(dateOption);
            if (optionMatcher.find()) {
                    Integer rangeValue = criteria.numberInput != null ? Integer.valueOf(criteria.numberInput) : null;
                result = dateOption.replace(optionMatcher.group(1), String.valueOf(rangeValue));
            } else if (isCustomDate(criteria)) {
                if (isDate(criteria.fieldType)) {
                        result = criteria.dateInput != null ? String.valueOf(criteria.dateInput) : null;
                } else if (isDatetime(criteria.fieldType)) {
                        result = criteria.dateTimeInput != null
                            ? criteria.dateTimeInput.format('yyyy-MM-dd\'T\'HH:mm:ss', UserInfo.getLocale()) + 'Z'
                            : null;
                    }
                }
            }
        } else if (isBoolean(criteria.fieldType)) {
            result = String.isNotBlank(criteria.input) ? criteria.input.toUpperCase() : null;
        } else if (isNumber(criteria.fieldType)) {
            result = criteria.numberInput != null ? String.valueOf(criteria.numberInput) : null;
        }
        return result;
    }

    private QueryEditor.CriteriaWrapper setFilterInputs(QueryEditor.CriteriaWrapper criteria) {
        String input = String.isNotBlank(this.value) ? this.value : null;
        Double numberInput;
        Date dateInput;
        Datetime dateTimeInput;

        if (isDate(this.fieldType) || isDatetime(this.fieldType)) {
            if (String.isNotBlank(this.value) && isRangeDate(this.value)) {
                Matcher matcher = DATE_RANGE_PATTERN.matcher(this.value);
                if (matcher.find()) {
                    numberInput = Double.valueOf(matcher.group(1));
                    input = this.value.replace(matcher.group(1), 'n');
                }
                // Note: if value is null that means this is a custom date and the user didn't provide a value (so filter is Date = NULL)
            } else if (this.value == null || isDateValue(this.value) || isDatetimeValue(this.value)) {
                input = 'customDate';
                if (isDate(this.fieldType)) {
                    dateInput = String.isNotBlank(this.value) ? Date.valueOf(this.value) : null;
                } else if (isDatetime(this.fieldType)) {
                    dateTimeInput = String.isNotBlank(this.value) ? (DateTime) JSON.deserialize('"' + this.value + '"', DateTime.class) : null;
                }
            }
        } else if (isNumber(this.fieldType)) {
            numberInput = String.isNotBlank(this.value) ? Double.valueOf(this.value) : null;
        }

        criteria.input = input;
        criteria.numberInput = numberInput;
        criteria.dateInput = dateInput;
        criteria.dateTimeInput = dateTimeInput;
        return criteria;
    }

    private Boolean isDateValue(String value) {
        Boolean result = false;
        try {
            Date.valueOf(this.value);
            result = true;
        } catch (TypeException e) {
            result = false;
        }
        return result;
    }

    private Boolean isDatetimeValue(String value) {
        Boolean result = false;
        try {
            Datetime.valueOf(this.value);
            result = true;
        } catch (TypeException e) {
            result = false;
        }
        return result;
    }

    private Boolean isCustomDate(QueryEditor.CriteriaWrapper criteria) {
        return criteria.input == 'customDate';
    }

    private Boolean isDate(String fieldType) {
        return fieldType == 'DATE';
    }

    private Boolean isDatetime(String fieldType) {
        return fieldType == 'DATETIME';
    }

    private Boolean isBoolean(String fieldType) {
        return fieldType == 'BOOLEAN';
    }

    private Boolean isNumber(String fieldType) {
        return NUMBER_TYPES.contains(fieldType);
    }

    private Boolean isRangeDate(String value) {
        Matcher matcher = DATE_RANGE_PATTERN.matcher(value);
        return matcher.matches();
    }

    private Boolean isCustomFilter(String fieldName) {
        return fieldName == 'Custom Filter';
    }

    private static final Pattern DATE_RANGE_PATTERN = Pattern.compile('.+_N_.+:([0-9]+)$');
    private static final Pattern DATE_RANGE_OPTION_PATTERN = Pattern.compile('.+_N_.+:(n)$');
    private static final Set<String> NUMBER_TYPES = new Set<String>{ 'DOUBLE', 'INTEGER', 'INT', 'PERCENT', 'CURRENCY' };
    private static final String NULL_VALUE = 'NULL';
}