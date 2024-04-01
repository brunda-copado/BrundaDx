public with sharing class EnvironmentVarPipelineRelatedListCtrl {
    public static final String PIPELINE_API_NAME = 'Deployment_Flow__c';
    public static final String ENVIRONMENT_API_NAME = 'Environment__c';
    
    @AuraEnabled
    public static List<Environmental_Variable__c> fetchData(Id recordId, String objectApiName){
        try {
            if(recordId == null){
                throw new ApplicationException('No Pipeline record found');
            }
            
            List<String> environmentId = new List<String>();
            if(objectApiName.containsIgnoreCase(PIPELINE_API_NAME)){
                Map<String,String> environmentIdByName = getEnvironment(recordId);
                if(!environmentIdByName.isEmpty()){
                    environmentId = environmentIdByName.values();
                }
            }else if(objectApiName.containsIgnoreCase(ENVIRONMENT_API_NAME)){
                environmentId.add(recordId);
            }
            List<Environmental_Variable__c> environmentVariableList = [SELECT Environment__c, Id, Name, Value__c, Environment__r.Name, Scope__c, LastModifiedDate FROM Environmental_Variable__c
            WHERE Environment__c IN :environmentId WITH SECURITY_ENFORCED 
            ORDER BY Name LIMIT 10000];

            String prevName = '';
            List<Environmental_Variable__c> enVarList = new List<Environmental_Variable__c>();
            for(Environmental_Variable__c environmentVariable : environmentVariableList)
            {
                if(String.isBlank(prevName) || (String.isNotBlank(prevName) && prevName != environmentVariable.Name)){
                    enVarList.add(environmentVariable);
                    prevName = environmentVariable.Name;
                }                               
            }
            return enVarList;
           
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static List<EnvironmentVarWrapper> fetchRows(Environmental_Variable__c environmentVar, String parentId, String sObjectName){
        try {
            Set<String> environmentNames = new Set<String>();
            List<EnvironmentVarWrapper> environmentWrappers = new List<EnvironmentVarWrapper>();
            Map<String,String> environmentIdByName = new Map<String,String>();
            if(sObjectName.containsIgnoreCase(PIPELINE_API_NAME) && String.isNotBlank(parentId)){
            environmentIdByName = getEnvironment(parentId);
                if(!environmentIdByName.isEmpty()){
                    environmentNames = environmentIdByName.keySet();
                }               
            }   
            
            if(environmentVar != null){
                List<Environmental_Variable__c> environmentVariableList = [SELECT Environment__c, Id, Name, Value__c, Environment__r.Name, Scope__c, LastModifiedDate FROM Environmental_Variable__c
                    WHERE Name =:environmentVar.Name WITH SECURITY_ENFORCED 
                    ORDER BY Environment__c];
                if(sObjectName.containsIgnoreCase(PIPELINE_API_NAME)){
                    for(Environmental_Variable__c environmentVariable :environmentVariableList){
                        if(environmentIdByName.containsKey(environmentVariable.Environment__r.Name)){
                            EnvironmentVarWrapper environmentWrapper = new EnvironmentVarWrapper(environmentVariable.Environment__r.Name, environmentVariable.Environment__c, environmentVariable.Value__c, environmentVariable.Id);
                            environmentWrappers.add(environmentWrapper);
                        }
                        if(environmentNames.contains(environmentVariable.Environment__r.Name)){
                            environmentNames.remove(environmentVariable.Environment__r.Name);
                        }
                    }
                }else if(sObjectName.containsIgnoreCase(ENVIRONMENT_API_NAME)){
                    for(Environmental_Variable__c environmentVariable :environmentVariableList){
                        if(environmentVariable.Environment__c == parentId){
                            EnvironmentVarWrapper environmentWrapper = new EnvironmentVarWrapper(environmentVariable.Environment__r.Name, environmentVariable.Environment__c, environmentVariable.Value__c, environmentVariable.Id);
                            environmentWrappers.add(environmentWrapper);
                        }
                    }
                    return environmentWrappers;
                }
            }
            for(String environmentName: environmentNames){
                EnvironmentVarWrapper environmentWrapper = new EnvironmentVarWrapper(environmentName, environmentIdByName.get(environmentName), '', '');
                environmentWrappers.add(environmentWrapper);
            }           
             
            return environmentWrappers;
        } catch (Exception e) {
            throw new ApplicationException(e.getMessage());
        }
    }

    private static Map<String,String> getEnvironment(String pipelineId){
        Map<Id, List<Deployment_Flow_Step__c>> pipelineConnectionMap= new DeploymentFlowStepsSelector().byPipeline(new Set<Id>{pipelineId});
        List<Deployment_Flow_Step__c> pipelineConnections = pipelineConnectionMap.get(pipelineId);
            
        Map<String,String> environmentIdByName = new Map<String,String>();

        for(Deployment_Flow_Step__c connection : pipelineConnections){
            environmentIdByName.put(connection.Source_Environment__r.Name,connection.Source_Environment__c);
            environmentIdByName.put(connection.Destination_Environment__r.Name,connection.Destination_Environment__c);
        }
        return environmentIdByName;
    }

    @AuraEnabled
    public static void onSave(String environmentVar, Boolean isEdit){
        try{
            List<Environmental_Variable__c> environmentVariableList = new List<Environmental_Variable__c>();
            if(!String.isEmpty(environmentVar)){
                Map<String, Object> environmentVariableMap = (Map<String, Object>)JSON.deserializeUntyped(environmentVar);
                List<Object> environment = (List<Object>)environmentVariableMap.get('environmentValue');

                if(!environment.isEmpty()){
                    for(Object env: environment){
                        Map<String, Object> envVarNameId = (Map<String, Object>)env;
                        Environmental_Variable__c envVar = new Environmental_Variable__c();
                        envVar.Name = String.valueOf(environmentVariableMap.get('variableName'));
                        envVar.Scope__c = String.valueOf(environmentVariableMap.get('scope'));
                        envVar.Environment__c = String.valueOf(envVarNameId.get('environmentId'));
                        envVar.Value__c = String.valueOf(envVarNameId.get('value'));
                        if(isEdit && String.isNotBlank(String.valueOf(envVarNameId.get('environmentVariableId')))){
                            envVar.Id = String.valueOf(envVarNameId.get('environmentVariableId'));
                        }
                        environmentVariableList.add(envVar);
                    }
                }        

            }
 
            if (!environmentVariableList.isEmpty()) {
                EnvironmentalVariableTriggerHelpler.bypassScopeCheck = true;
                Utilities.Secure_DML(environmentVariableList, Utilities.DML_Action.UPS, schema.SObjectType.Environmental_Variable__c);
            }
        }catch (Exception e) {
            String errorMsg = e.getMessage();
            String pureErrorMsg = errorMsg.substringAfter('_EXCEPTION,');
            pureErrorMsg = pureErrorMsg.Substring(0, (pureErrorMsg.length()-4));
            throw new ApplicationException(pureErrorMsg);
        }
    }

    @AuraEnabled
    public static void onDelete(Environmental_Variable__c environmentVariable, String sObjectName){
        try{
            if(environmentVariable != null){
                List<Environmental_Variable__c> environmentVariableList = new List<Environmental_Variable__c>();
                if(sObjectName.containsIgnoreCase(PIPELINE_API_NAME)){
                    environmentVariableList = [SELECT Environment__c, Id, Name, Value__c, Environment__r.Name, Scope__c, LastModifiedDate FROM Environmental_Variable__c
                    WHERE Name =:environmentVariable.Name WITH SECURITY_ENFORCED LIMIT 10000];
                }else if(sObjectName.containsIgnoreCase(ENVIRONMENT_API_NAME)){
                    environmentVariableList = [SELECT Environment__c, Id, Name, Value__c, Environment__r.Name, Scope__c, LastModifiedDate FROM Environmental_Variable__c
                    WHERE Id =:environmentVariable.Id WITH SECURITY_ENFORCED LIMIT 10000];
                }               

                if(!environmentVariableList.isEmpty()){
                    Utilities.Secure_DML(environmentVariableList, Utilities.DML_Action.DEL, schema.SObjectType.Environmental_Variable__c);
                }
            }
        }catch (Exception e) {
            throw new ApplicationException(e.getMessage());
        }
    }


    public class EnvironmentVarWrapper {
        @AuraEnabled
        public String environment { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String environmentId { get; set; }
        @AuraEnabled
        public String environmentVariableId {get; set;}

        public EnvironmentVarWrapper(String environment, String environmentId, String value, String environmentVariableId) {
            this.environment = environment;
            this.environmentId = environmentId;
            this.value = value;        
            this.environmentVariableId = environmentVariableId;    
        }
    }

}