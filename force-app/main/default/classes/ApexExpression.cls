public inherited sharing class ApexExpression extends DynamicExpression {
    private static final Pattern APEX_PATTERN = Pattern.compile(
        '(?i)\\{\\s*\\$?(Context|Source|Destination|User|Pipeline).Apex.([A-Za-z0-9_\\.]+)(\\.(matches)\\s*\\(\\s*(\'|")?[^\']*(\'|")?\\s*\\))?\\s*\\}'
    );

    private SObject record;

    @Testvisible
    private static String mockValue;

    // CONSTRUCTOR

    public ApexExpression(String contextId) {
        this.contextId = contextId;
    }

    // PUBLIC

    public override void prepare() {
        String objectName = String.isNotBlank(contextId) ? objectName(recordId()) : null;

        if (String.isNotBlank(objectName) && objectName.equalsIgnoreCase('Deployment_Job__c')) {
            record = [SELECT Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM Deployment_Job__c WHERE Id = :contextId WITH SECURITY_ENFORCED];
        } else if (String.isNotBlank(objectName) && objectName.equalsIgnoreCase('JobStep__c')) {
            record = [SELECT Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM JobStep__c WHERE Id = :contextId WITH SECURITY_ENFORCED];
        }
    }

    public override Boolean matches(String expression) {
        return APEX_PATTERN.matcher(expression).matches();
    }

    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        String result = null;
        Matcher apexMatcher = APEX_PATTERN.matcher(expression);

        if (apexMatcher.matches()) {
            try {
                String className = apexMatcher.group(2);
                String contextType = apexMatcher.group(1);

                Id parentId = parentId(record, contextType, expression);
                String value = getValue(className, parentId);

                if (String.isNotBlank(apexMatcher.group(3))) {
                    result = isMatching(apexMatcher.group(3), value);
                } else {
                    result = value;
                }
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage() + Label.StackTrace + ' ' + ex.getStackTraceString());
            }
        }

        return new Jobs.DynamicExpressionEvaluateResult(expression, result);
    }

    // PRIVATE

    private String getValue(String className, Id parentId) {
        String result = null;

        if (Test.isRunningTest() && mockValue != null) {
            result = mockValue;
        } else {
            result = instance(className).execute(parentId);
        }

        return result;
    }

    private ParameterExpressionCallable instance(String className) {
        ParameterExpressionCallable result = null;

        try {
            result = (ParameterExpressionCallable) Type.forName(namespace(className), handler(className))?.newInstance();
        } catch (Exception ex) {
            result = null;
        }

        if (result == null) {
            throw new ApplicationException(Label.InvalidExpressionClass + className);
        }

        return result;
    }
}