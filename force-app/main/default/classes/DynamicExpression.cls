@SuppressWarnings('PMD.ApexSharingViolations,PMD.CyclomaticComplexity')
public abstract class DynamicExpression {
    protected String contextId;
    protected List<String> expressions = new List<String>();

    // CONSTRUCTOR

    public void add(String expression) {
        if (matches(expression)) {
            expressions.add(expression);
        }
    }

    public virtual Boolean matches(String expression) {
        return true;
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public virtual void prepare() {
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public virtual Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        return null;
    }

    public Boolean hasParameters() {
        return !expressions.isEmpty();
    }

    public static List<Jobs.DynamicExpressionEvaluateResult> masked(List<Jobs.DynamicExpressionEvaluateResult> inputs) {
        List<Jobs.DynamicExpressionEvaluateResult> result = new List<Jobs.DynamicExpressionEvaluateResult>();

        for (Jobs.DynamicExpressionEvaluateResult input : inputs) {
            result.add(masked(input));
        }

        return result;
    }

    public static Jobs.DynamicExpressionEvaluateResult masked(Jobs.DynamicExpressionEvaluateResult input) {
        Jobs.DynamicExpressionEvaluateResult result = input.clone();

        if (input.isSensitive == true) {
            result.value = '****';
        }

        return result;
    }

    public List<String> matchingExpressions() {
        return expressions;
    }

    protected String getValue(SObject record, String fieldName) {
        if (record != null && fieldName.contains('.')) {
            return getValue((SObject) record?.getSobject(fieldName.substringBefore('.')), fieldName.substringAfter('.'));
        } else if (record != null) {
            return String.valueOf(record.get(fieldName));
        } else {
            return '';
        }
    }

    protected String objectName(String strRecordId) {
        Id recordId = String.isNotBlank(strRecordId) ? Id.valueOf(strRecordId) : null;

        return recordId?.getSobjectType()?.getDescribe()?.getLocalName();
    }

    protected Id recordId() {
        return recordId(Label.JobStep);
    }

    protected String isMatching(String regexMatcher, String value) {
        value = value == null ? '' : value;
        String unsafeRegex = regexMatcher.substringAfter('.matches(').substringBeforeLast(')');
        if (isWrappedInQuotes(unsafeRegex)) {
            unsafeRegex = unsafeRegex.substring(1, unsafeRegex.length() - 1);
        }

        String regex = Pattern.quote(unsafeRegex).replace('*', '\\E.*\\Q').replace('?', '\\E.\\Q');

        return String.valueOf(Pattern.compile(regex).matcher(value).matches());
    }

    protected Id recordId(String expectedContext) {
        try {
            return Id.valueOf(contextId);
        } catch (Exception ex) {
            throw new ApplicationException(
                String.format(Label.invalidContextId, new List<String>{ String.join(expressions, ', '), expectedContext })
            );
        }
    }

    protected String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    protected String handler(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

    protected Boolean matches(Pattern regexPattern, String expression) {
        return regexPattern.matcher(expression).matches();
    }

    public String getValueFromJson(String jsonInput, String propertyName) {
        String result = null;

        if(String.isNotBlank(jsonInput)) {
            Object o = getValueFromJson( (Map<String, Object>)JSON.deserializeUntyped(jsonInput), propertyName);
            // if is a string, return the actual value. Otherwise, serialize the JSON... works with array, object, datetime, booleans, integers
            if(o instanceof String) {
                result = String.valueOf(o);
            } else if(o != null) {
                result = JSON.serialize(o);
            }
        }

        return result;
    }

    private Object getValueFromJson(Map<String, Object> jsonResult, String propertyName) {
        String[] t = propertyName.split('\\.', 2);

        if(t.size() > 1) {
            return jsonResult.get(t[0]) != null
                ? getValueFromJson( (Map<String, Object>)jsonResult.get(t[0]), t[1])
                : null;
        } else {
            return jsonResult.get(propertyName);
        }
    }

    protected String trimQuotes(String value) {
        return (value != null && value.startsWith('"') && value.endsWith('"')) ? value.subString(1, value.length() - 1) : value;
    }

    protected Id parentId(SObject record, String contextType, String expression) {
        String result = null;

        if (contextType.equalsIgnoreCase('User')) {
            result = UserInfo.getUserId();
        } else if (contextType.equalsIgnoreCase('Context')) {
            result = contextId;
        } else {
            String fieldName = contextType + '_Id__c';
            result = (String) record?.get(fieldName);
        }

        if (result == null) {
            throw new ApplicationException(String.format(Label.contextRequired, new List<String>{ contextType, expression }));
        }

        return result;
    }

    private Boolean isWrappedInQuotes(string regex) {
        return ((regex.startsWith('"') && regex.endsWith('"')) || (regex.startsWith('\'') && regex.endsWith('\'')));
    }
}