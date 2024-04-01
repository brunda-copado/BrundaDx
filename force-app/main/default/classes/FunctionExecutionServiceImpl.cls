public inherited sharing class FunctionExecutionServiceImpl {
    // PUBLIC

    public static CopadoFunctions.ExecuteResponse execute(CopadoFunctions.ExecuteRequest request) {
        if (String.isBlank(request.functionApiName)) {
            throw new ApplicationException(
                String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String>{ 'Function API Name' }, ', ') })
            );
        }

        return new CopadoFunctions.ExecuteResponse(
            new FunctionEngine(request.functionApiName)
                .contextId(request.contextId)
                .parameters(getParameters(request.parameters))
                .resultCallback(request.callback)
                .options(getParameters(request.options))
                .execute()
        );
    }

    // PRIVATE

    private static List<Parameter> getParameters(List<CopadoFunctions.FunctionParameter> functionParams) {
        List<Parameter> result = new List<Parameter>();

        if (functionParams != null) {
            for (CopadoFunctions.FunctionParameter param : functionParams) {
                result.add(new Parameter(param.name, param.value).sensitive(param.sensitive).required(param.required));
            }
        }

        return result;
    }
}