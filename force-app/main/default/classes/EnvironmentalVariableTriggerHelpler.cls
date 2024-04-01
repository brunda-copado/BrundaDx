public with sharing class EnvironmentalVariableTriggerHelpler {

    public static Map<Id,Set<String>> existingEnvironmentalVariables { get; set; }
    public static Map<String,List<Environmental_Variable__c>> environmentVariableMapByName { get; set; }
    public static boolean bypassScopeCheck = false;

    public static void prepareData() {
        Set<String> environmentSet = new Set<String>();
        Set<String> environmentVariableNames = new Set<String>();
        existingEnvironmentalVariables = new Map<Id,Set<String>>();
        environmentVariableMapByName = new Map<String,List<Environmental_Variable__c>>();
        String prevName = ''; 
        List<Environmental_Variable__c> environmentVariableList = new List<Environmental_Variable__c>();

        for(SObject so : Trigger.new) {
            Environmental_Variable__c envVar = (Environmental_Variable__c) so;
            environmentSet.add(envVar.Environment__c);
            environmentVariableNames.add(envVar.Name);
        }
        
        for(Environmental_Variable__c ev : [SELECT Name, Environment__c, Value__c, Scope__c FROM Environmental_Variable__c WHERE (Environment__c != NULL AND Environment__c = :environmentSet) OR Name =:environmentVariableNames]) {
            populateEnvironmentalVariablesMap(ev.Id, (ev.Name + ev.Environment__c).toLowerCase());
            populateEnvironmentalVariablesMap(ev.Id, (ev.Value__c + ev.Environment__c).toLowerCase());
            if (String.isNotBlank(ev.Scope__c)) {
                populateEnvironmentalVariablesMap(ev.Id, (ev.Name + ev.Environment__c+ sort(ev.Scope__c)).toLowerCase());
                populateEnvironmentalVariablesMap(ev.Id, (ev.Value__c + ev.Environment__c+ sort(ev.Scope__c)).toLowerCase());
            }

            if(String.isBlank(prevName) || (String.isNotBlank(prevName) && prevName == ev.Name)){
                environmentVariableList.add(ev);
                prevName = ev.Name;
            }else if(String.isNotBlank(prevName) && prevName != ev.Name && !environmentVariableMapByName.containsKey(prevName)){
                environmentVariableMapByName.put(prevName, environmentVariableList);
                environmentVariableList = new List<Environmental_Variable__c>();
                environmentVariableList.add(ev);
                prevName = ev.Name;
            }
        }
        environmentVariableMapByName.put(prevName,environmentVariableList);
    }

    public static void checkForDuplicates(Environmental_Variable__c ev) {
        for (Id envId : existingEnvironmentalVariables.keySet()) {
            if (String.isBlank(ev.Scope__c)) {
                if (matchDuplicateNameAndEnv(ev , envId)) {
                    ev.addError(Label.DUPLICATE_EV_NAME_AND_ENV);
                }
                else if (matchDuplicateValAndEnv(ev , envId)) {
                    ev.addError(Label.DUPLICATE_EV_VAL_AND_ENV);
                }    
            }
            else {
                if (matchDuplicateNameAndEnv(ev , envId)) {
                    ev.addError(Label.DUPLICATE_EV_NAME_AND_ENV);
                }
                else if (matchDuplicateNameEnvAndScope(ev , envId)) {
                    ev.addError(Label.DUPLICATE_EV_NAME_ENV_AND_SCOPE);
                }
                else if (matchDuplicateValEnvAndScope(ev , envId)) {
                    ev.addError(Label.DUPLICATE_EV_VAL_ENV_AND_SCOPE);
                }
            }
        }
    }

    private static boolean matchDuplicateNameAndEnv(Environmental_Variable__c ev , Id envId){
        return (existingEnvironmentalVariables.get(envId).contains((ev.Name + ev.Environment__c).toLowerCase())) && ( String.isBlank(ev.Id) || envId != ev.Id);
    }

    private static boolean matchDuplicateValAndEnv(Environmental_Variable__c ev , Id envId){
        return (existingEnvironmentalVariables.get(envId).contains((ev.Value__c + ev.Environment__c).toLowerCase())) && ( String.isBlank(ev.Id) || envId != ev.Id);
    }

    private static boolean matchDuplicateNameEnvAndScope(Environmental_Variable__c ev , Id envId){
        return (existingEnvironmentalVariables.get(envId).contains((ev.Name + ev.Environment__c + sort(ev.Scope__c)).toLowerCase())) && ( String.isBlank(ev.Id) || envId != ev.Id);
    }

    private static boolean matchDuplicateValEnvAndScope(Environmental_Variable__c ev , Id envId){
        return (existingEnvironmentalVariables.get(envId).contains((ev.Value__c + ev.Environment__c + sort(ev.Scope__c)).toLowerCase())) && ( String.isBlank(ev.Id) || envId != ev.Id);
    }

    private static String sort(String str) {
        List<String> strValues = str.split(';');
        strValues.sort();
        return String.join(strValues, ';');
    }

    private static void populateEnvironmentalVariablesMap(Id envId, String str){
        if(!existingEnvironmentalVariables.containsKey(envId)){
            existingEnvironmentalVariables.put(envId, new Set<String>{str});
        }
        else{
            existingEnvironmentalVariables.get(envId).add(str);
        }
    }

    public static void checkForScopeChange(Environmental_Variable__c ev){
        List<Environmental_Variable__c> environmentVariableList = new List<Environmental_Variable__c>();
        Integer scopeChange = 0;
        if(environmentVariableMapByName.containsKey(ev.Name)){
            environmentVariableList = environmentVariableMapByName.get(ev.Name);
    
            for(Environmental_Variable__c environmentVariable : environmentVariableList){
                if(ev.Scope__c != environmentVariable.Scope__c){
                    scopeChange++;
                }
            }

            if(environmentVariableList.size()>=scopeChange && !bypassScopeCheck){
                ev.addError(Label.SCOPE_CHANGE_ERROR);
            }
        }
    }

}