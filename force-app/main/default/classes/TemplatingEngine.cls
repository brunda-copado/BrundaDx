public inherited sharing class TemplatingEngine {
    private static final Pattern NAME_PATTERN = Pattern.compile('[a-zA-Z_][a-zA-Z0-9_]*');

    private List<Parameter> parameters;
    private List<DynamicExpression> parsers;
    private Id contextId;

    // CONSTRUCTOR

    public TemplatingEngine(String contextId, List<Parameter> parameters) {
        this.parameters = parameters != null ? parameters : new List<Parameter>();
        this.contextId = asId(contextId);
    }

    // PUBLIC
    @SuppressWarnings('PMD.CyclomaticComplexity')
    public List<Parameter> parse() {
        Logger.trace(this.contextId, 'TemplatingEngine.parse started', '', masked(this.parameters));
        List<String> expressions = new List<String>();

        for (Parameter parameter : parameters) {
            assertParameterName(parameter.name);
            expressions.add(parameter.value);
        }

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(this.contextId, expressions);
        List<Jobs.DynamicExpressionEvaluateResult> responses = Jobs.DynamicExpression.evaluate(request);

        for(Integer i = 0; i < responses.size(); i++) {
            if(parameters[i].required == true && String.isNotBlank(responses[i].errorMessage)) {
                throw new ApplicationException(responses[i].errorMessage);
            } else if(parameters[i].required == true && String.isBlank(responses[i].value) && parameters[i].name.equalsIgnoreCase('git_json')) {
                throw new ApplicationException(Label.MissingGitParameterValue);
            } else if(parameters[i].required == true && String.isBlank(responses[i].value)) {
                throw new ApplicationException(String.format(Label.MissingParameterValue, new List<String>{ parameters[i].name }));
            }

            parameters[i].value = responses[i].value;
            parameters[i].sensitive = responses[i].isSensitive;
        }

        Logger.trace(this.contextId, 'TemplatingEngine.parse completed', '', masked(this.parameters));

        return parameters;
    }

    // PRIVATE

    private Id asId(String contextId) {
        try {
            return String.isBlank(contextId) ? null : Id.valueOf(contextId);
        } catch (Exception ex) {
            throw new ApplicationException(Label.InvalidContextIdValue);
        }
    }


    private void assertParameterName(String name) {
        Matcher nameMatcher = NAME_PATTERN.matcher(name);

        if (!nameMatcher.matches()) {
            throw new ApplicationException(String.format(Label.InvalidNameformat, new List<String>{ name }));
        }
    }


    public static List<Parameter> masked(List<Parameter> parameters) {
        List<Parameter> result = new List<Parameter>();

        for(Parameter parameter : parameters) {
            result.add(masked(parameter));
        }

        return result;
    }


    private static Parameter masked(Parameter parameter) {
        Parameter result = new Parameter();
        result.name = parameter.name;
        result.value = parameter.sensitive == true? '****' : parameter.value;
        result.defaultValue = parameter.sensitive == true? '****' : parameter.defaultValue;
        result.required = parameter.required;
        result.sensitive = parameter.sensitive;
        return result;
    }
}