public with sharing class FunctionComponentController {

    public static String namespace {
        get {return Settings.ns;}
    }

    @RemoteAction
    public static Function functionParameters(Id functionId, Id deploymentTaskId) {

        Function__c record = new FunctionsSelector().byId(functionId);
        List<Parameter> parameters = functionParameters(record, deploymentTaskId);

        return new Function(record, parameters);
    }

    // PRIVATE

    private static List<Parameter> functionParameters(Function__c  function, Id taskId) {
        List<Parameter> result = (List<Parameter>) JSON.deserialize(function.Parameters__c, List<Parameter>.class);
        Map<String, String> taskParametersByName = taskParametersByName(taskId);

        for(Parameter parameter : result) {
            if(taskParametersByName.containsKey(parameter.name)) {
                parameter.value = taskParametersByName.get(parameter.name);
            } else {
                parameter.value = parameter.defaultValue;
            }
        }

        return result;
    }

    private static Map<String, String> taskParametersByName(Id taskId) {
        Map<String, String> result = new Map<String, String>();

        for(Parameter parameter : taskParameters(taskId)) {
            result.put(parameter.name, parameter.value);
        }

        return result;
    }


    private static List<Parameter> taskParameters(Id taskId) {
        List<Parameter> result = new List<Parameter>();

        Deployment_Task__c task = new DeploymentTasksSelector().byId(taskId);

        if(String.isNotBlank(task?.dataJSON__c)) {
            DataJSON dataJSON = (DataJSON) JSON.deserialize(task.dataJSON__c, DataJSON.class);
            result = dataJSON.functionParameters;
        }

        return result;
    }


    // INNER

    public class Function {
        public String apiName;
        public List<Parameter> parameters;

        public Function(Function__c function, List<Parameter> parameters) {
            apiName = function.API_Name__c;
            this.parameters = parameters;
        }
    }

    public class DataJSON {
        public String functionAPIName;
        public List<Parameter> functionParameters;
    }
}