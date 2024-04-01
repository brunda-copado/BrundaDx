public inherited sharing class UserExpression extends DynamicExpression {
    private static final Pattern USER_PATTERN = Pattern.compile( '(?i)\\{\\s*\\$?(User|Context|Pipeline)\\.([a-z0-9_]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}');

    private User loggedInUser;

    // CONSTRUCTOR

    public UserExpression(String contextId) {
        this.contextId = contextId;
    }

    // PUBLIC

    public override void prepare() {
        loggedInUser = loggedInUser();
    }

    public override Boolean matches(String expression) {
        Matcher userMatcher = USER_PATTERN.matcher(expression);

        return userMatcher.matches();
    }

    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        String result = null;
        Matcher userMatcher = USER_PATTERN.matcher(expression);

        if (userMatcher.matches()) {
            String propertyName = userMatcher.group(2);
            String value = (String) loggedInUser.get(propertyName);

            if(String.isBlank(userMatcher.group(3))) {
                result = value;
            } else {
                result = isMatching(userMatcher.group(3), value);
            }
        }

        return new Jobs.DynamicExpressionEvaluateResult(expression, result);
    }

    // PRIVATE

    @SuppressWarnings('PMD.UnusedLocalVariable')
    private User loggedInUser() {
        User result = null;

        List<String> userFields = userFields();

        if (!userFields.isEmpty()) {
            Id userId = UserInfo.getUserId();
            String query = 'SELECT ' + String.join(userFields, ', ') + ' FROM User WHERE Id = :userId WITH SECURITY_ENFORCED';
            result = Database.query(String.escapeSingleQuotes(query));
        }

        return result;
    }

    private List<String> userFields() {
        Set<String> result = new Set<String>();

        for (String expression : expressions) {
            String value = expression;

            Matcher userMatcher = USER_PATTERN.matcher(value);

            if (userMatcher.matches()) {
                result.add(userMatcher.group(2));
            }
        }

        return new List<String>(result);
    }
}