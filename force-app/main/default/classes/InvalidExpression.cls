public with sharing class InvalidExpression extends DynamicExpression {
    private static final Pattern INVALID_PATTERN = Pattern.compile('\\{\\$?[a-zA-Z_][a-zA-Z0-9_]*\\.[a-zA-Z_][a-zA-Z0-9_]*(\\.[a-zA-Z_][a-zA-Z0-9_]*)?\\}');

    // PUBLIC

    public override Boolean matches(String expression) {
        Matcher matcher = INVALID_PATTERN.matcher(expression);

        return matcher.matches();
    }


    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        if(matches(expression)) {
            throw new ApplicationException(Label.InValidExpression + expression);
        }

        return null;
    }
}