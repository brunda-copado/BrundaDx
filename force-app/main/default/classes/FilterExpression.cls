public with sharing class FilterExpression {
    private static final Pattern FILTER_EXPRESSION_PATTERN = Pattern.compile(
        '(?i)\\{\\s*\\$?(Changes|Context).(Name|Directory|Type).([A-Za-z0-9_\\s"\'\\.\\-\\/\\(\\)\\*]+)\\}'
    );

    private static final Pattern CONDITION_PATTERN = Pattern.compile(
        '(?i)(matches|equals|notEquals|contains|notContains|startsWith|notStartswith|endsWith|notEndsWith)\\(([A-Za-z0-9_\\s"\'\\.\\-\\/\\*\\|]+)\\)'
    );

    private String expression;
    private List<User_Story_Metadata__c> metadataChanges;

    public FilterExpression(String expression) {
        this.expression = expression;
    }

    public FilterExpression metadataChanges(List<User_Story_Metadata__c> metadataChanges) {
        this.metadataChanges = metadataChanges;
        return this;
    }

    public Boolean evaluate() {
        Boolean result = false;
        Matcher matcher = FILTER_EXPRESSION_PATTERN.matcher(expression);

        if (!matcher.matches()) {
            throw new ApplicationException(String.format(Label.Invalid_Filter_Criteria_Expression, new List<Object>{ expression }));
        }

        String scope = matcher.group(1);
        String node = matcher.group(2);
        List<String> candidates = getCandidates(scope, node);
        String conditionExpression = matcher.group(3);
        Condition condition = condition(conditionExpression);
        result = anyMatch(candidates, condition.operator, condition.value);

        return result;
    }

    private List<String> getCandidates(String scope, String node) {
        List<String> result = new List<String>();
        switch on scope {
            // Note: Context scope not implemented yet. Ignore for now
            when 'Changes' {
                result = new Changes().metadata(metadataChanges).getValues(node);
            }
        }
        return result;
    }

    private Condition condition(String conditionExpression) {
        Condition result = new Condition();
        Matcher matcher = CONDITION_PATTERN.matcher(conditionExpression);
        if (matcher.matches()) {
            result.operator = matcher.group(1);
            result.value = matcher.group(2).replaceAll('\'', '').replaceAll('\"', '');
        }
        return result;
    }

    public Boolean anyMatch(List<String> candidates, String operator, String value) {
        Boolean result = false;

        for (String candidate : candidates) {
            Boolean matches = false;
            switch on operator {
                when 'matches', 'equals' {
                    matches = matches(candidate, value);
                }
                when 'notEquals' {
                    matches = !matches(candidate, value);
                }
                when 'contains' {
                    matches = matches(candidate, '*' + value + '*');
                }
                when 'notContains' {
                    matches = !matches(candidate, '*' + value + '*');
                }
                when 'startsWith' {
                    matches = matches(candidate, value + '*');
                }
                when 'notStartsWith' {
                    matches = !matches(candidate, value + '*');
                }
                when 'endsWith' {
                    matches = matches(candidate, '*' + value);
                }
                when 'notEndsWith' {
                    matches = !matches(candidate, '*' + value);
                }
            }
            if (matches) {
                result = matches;
                break;
            }
        }

        return result;
    }

    private Boolean matches(String value, String regex) {
        return Pattern.compile(fixRegex(regex)).matcher(value).matches();
    }

    private String fixRegex(String regex) {
        return Pattern.quote(regex).replace('*', '\\E.*\\Q').replace('?', '\\E.\\Q');
    }

    private with sharing class Condition {
        private String operator;
        private String value;
    }
}