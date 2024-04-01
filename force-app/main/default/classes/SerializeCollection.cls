global with sharing class SerializeCollection {
    global class InvocableVariables {
        @InvocableVariable(label='Parameter List' required=false)
        global List<Parameter> parameters;
        @InvocableVariable(label='Collection' required=false)
        global List<String> collection;
        @InvocableVariable(label='Suppress Null Values?' required=false)
        global Boolean suppressNulls = false;
    }

    @InvocableMethod(label='Serialize Collection')
    global static List<String> execute(List<InvocableVariables> variables) {
        return serialize(variables);
    }

    private static List<String> serialize(List<InvocableVariables> variables) {
        List<String> result = new List<String>();
        if (variables[0].parameters != null) {
            result.add(JSON.serialize(variables[0].parameters, variables[0].suppressNulls));
        }
        if (variables[0].collection != null) {
            result.add(JSON.serialize(variables[0].collection, variables[0].suppressNulls));
        }
        return result;
    }
}