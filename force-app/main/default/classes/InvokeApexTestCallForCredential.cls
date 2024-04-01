global with sharing class InvokeApexTestCallForCredential {
    global with sharing class InvocableVariables {
        @InvocableVariable(label='Credential Id' required=true)
        global Id credentialId;
    }

    @InvocableMethod(label='Execute Apex Test' description='Execute apex test class for given credential')
    global static void execute(List<InvocableVariables> variables) {
        CredentialsButtonsHandler.callNecessaryOperation(variables[0].credentialId, CredentialsButtonsHandler.APEX_TEST);
    }
}