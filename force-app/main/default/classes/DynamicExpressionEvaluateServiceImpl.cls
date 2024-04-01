public inherited sharing class DynamicExpressionEvaluateServiceImpl {
    private static List<DynamicExpression> parsers;

    // PUBLIC

    public static List<Jobs.DynamicExpressionEvaluateResult> execute(Jobs.DynamicExpressionEvaluateRequest request) {
        Logger.trace(request.contextId, 'Jobs.DynamicExpressionEvaluateResult.execute started', '', request.dynamicExpressions);

        List<Jobs.DynamicExpressionEvaluateResult> result = new List<Jobs.DynamicExpressionEvaluateResult>();

        if (request.dynamicExpressions.isEmpty()) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Dynamic Expressions'}));
        }

        prepare(request);

        for (String expression : request.dynamicExpressions) {
            expression = String.isNotBlank(expression) ? expression.trim() : '';

            DynamicExpression parser = getParser(expression);
            if(parser != null) {
                try {
                    String className = String.valueOf(parser).split(':')[0];

                    Logger.trace(request.contextId, className + '.parse started', '', parser.matchingExpressions());

                    Jobs.DynamicExpressionEvaluateResult parsedResult = parser.parse(expression);
                    result.add(parsedResult);
                    Logger.trace(request.contextId, className + '.parse completed', '', DynamicExpression.masked(parsedResult));
                } catch(Exception ex) {
                    result.add(new Jobs.DynamicExpressionEvaluateResult(expression, ex));
                }
            } else {
                result.add(new Jobs.DynamicExpressionEvaluateResult(expression));
            }
        }
        Logger.trace(request.contextId, 'Jobs.DynamicExpressionEvaluateResult.execute completed', '', DynamicExpression.masked(result));

        return result;
    }


    // PRIVATE

    private static void prepare(Jobs.DynamicExpressionEvaluateRequest request) {

        // Note: Order of parsers matter
        parsers = new List<DynamicExpression> {
            new BranchExpression(request.contextId),
            new ApexExpression(request.contextId),
            new StepExpression(request.contextId),
            new CredentialExpression(request.contextId),
            new SystemExpression(request.contextId),
            new RepositoryExpression(request.contextId),
            new SObjectExpression(request.contextId),
            new UserExpression(request.contextId),
            new InvalidExpression()
        };

        for (String expression : request.dynamicExpressions) {
            getParser(expression)?.add(expression);
        }

        for (DynamicExpression parser : parsers) {
            if (parser.hasParameters()) {
                String className = String.valueOf(parser).split(':')[0];
                Logger.trace(request.contextId, className + '.prepare started', '', parser.matchingExpressions());
                parser.prepare();
                Logger.trace(request.contextId, className + '.prepare completed', '', parser.matchingExpressions());
            }
        }
    }


    private static DynamicExpression getParser(String expression) {
        DynamicExpression result = null;

        if(String.isNotBlank(expression)) {
            for (DynamicExpression parser : parsers) {
                if (parser.matches(expression)) {
                    result = parser;
                    break;
                }
            }
        }

        return result;
    }
}