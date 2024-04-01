public with sharing class FilterCriteria {
    private static final Pattern EXPRESSION_PATTERN = Pattern.compile('.*(\\{\\s*\\$[A-Za-z0-9_\\s"\'\\.\\,\\(\\-\\/\\)\\*]+\\})+.*');

    private String filterCriteria;
    private List<User_Story_Metadata__c> metadataChanges;

    public FilterCriteria(String filterCriteria) {
        this.filterCriteria = filterCriteria;
    }

    public FilterCriteria metadataChanges(List<User_Story_Metadata__c> metadataChanges) {
        this.metadataChanges = metadataChanges;
        return this;
    }

    public Boolean evaluate() {
        Boolean result = false;

        String logic = filterCriteria;

        for (String expression : filterCriteria.split('\\s[&|]{2}\\s')) {
            Matcher matcher = EXPRESSION_PATTERN.matcher(expression);
            if (matcher.matches()) {
                String innerExpression = matcher.group(1);
                Boolean expressionResult = new FilterExpression(innerExpression).metadataChanges(metadataChanges).evaluate();
                logic = logic.replace(expression, expression.replace(innerExpression, String.valueOf(expressionResult).toUpperCase()));
            }
        }

        logic = changeLogicalOperators(logic);
        if (logic.contains('(') || logic.contains(')')) {
            logic = removeSpacesAroundBraces(logic);
        }

        result = PredicateBooleanExpression.eval(logic);

        return result;
    }

    private String changeLogicalOperators(String logic) {
        return logic.replaceAll('\\s[&]{2}\\s', ' AND ').replaceAll('\\s[|]{2}\\s', ' OR ');
    }

    private String removeSpacesAroundBraces(String logic) {
        return logic.replace('( ', '(').replace(' )', ')');
    }
}