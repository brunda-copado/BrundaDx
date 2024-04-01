@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class EnvironmentVariables implements ParameterExpressionCallable {
    // GLOBAL

    global String execute(Id environmentId) {
        List<EnvironmentVariablesRecord> result = new List<EnvironmentVariablesRecord>();
        for (Environmental_Variable__c environmentVariable : getEnvironmentVariables(environmentId)) {
            result.add(new EnvironmentVariablesRecord(environmentVariable.Name, environmentVariable.Value__c, environmentVariable.Scope__c));
        }

        return JSON.serialize(result);
    }

    // PRIVATE

    private List<Environmental_Variable__c> getEnvironmentVariables(Id environmentId) {
        return [SELECT Id, Name, Value__c, Scope__c FROM Environmental_Variable__c WHERE Environment__c = :environmentId WITH SECURITY_ENFORCED];
    }

    // WRAPPER

    public class EnvironmentVariablesRecord {
        public String name { get; set; }
        public String value { get; set; }
        public String scope { get; set; }

        public EnvironmentVariablesRecord(String n, String v, String s) {
            this.name = n;
            this.value = v;
            this.scope = s;
        }
    }
}