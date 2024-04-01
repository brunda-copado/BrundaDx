@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RunCopadoFunction {
    /**
     * Custom object for storing InvocableVariables. InvocableMethods requires List<T> where T is a user defined type.
     * You cannot pass Boolean, String or any other primitive type as a variable to an Invocable method.
     * Custom Object types, sObjects or Ids are the only supported types.
     * @see InvocableVariable
     * @see InvocableMethod
     */
    global class InvocableVariables {
        @InvocableVariable(label='Function API Name' required=true)
        global String functionApiName;
        @InvocableVariable(label='Context Id' required=false)
        global String contextId;
        @InvocableVariable(label='Parameters' required=false)
        global List<Parameter> parameters;
        @InvocableVariable(label='Parameters (JSON)' required=false)
        global String parametersJSON;
        @InvocableVariable(label='Options' required=false)
        global List<Parameter> options;
        @InvocableVariable(label='Options (JSON)' required=false)
        global String optionsJSON;
        @InvocableVariable(label='Result Apex Callback' required=false)
        global String resultCallback;
        @InvocableVariable(label='Show Validation Errors' required=false description='If set to true, throws an error when the validation fails')
        global Boolean showValidationErrors = false;
    }
    /**
     * Invocable method for executing Copado Functions.
     * @param  variables InvocableVariables
     * @return           void
     * @see InvocableVariable
     * @see InvocableMethod
     */
    @InvocableMethod(label='Invoke Copado Function' description='Invokes a Copado Function that sends a callout to the desired backend endpoint.')
    global static List<String> execute(List<InvocableVariables> variables) {
        InvocableVariables variable = variables[0];

        if (String.isNotBlank(variable.parametersJSON)) {
            variable.parameters = (List<Parameter>) JSON.deserialize(variable.parametersJSON, List<Parameter>.class);
        }

        if (String.isNotBlank(variable.optionsJSON)) {
            variable.options = (List<Parameter>) JSON.deserialize(variable.optionsJSON, List<Parameter>.class);
        }

        return new List<String>{
            new FunctionEngine(variable.functionApiName)
                .contextId(variable.contextId)
                .parameters(variable.parameters)
                .options(variable.options)
                .resultCallback(variable.resultCallback)
                .showValidationErrors(variable.showValidationErrors)
                .execute()
        };
    }
}