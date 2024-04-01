global with sharing class InvokeStaticCodeAnalysisForCredential {
    global with sharing class InvocableVariables {
        @InvocableVariable(label='Credential Id' required=true)
        global Id credentialId;
    }

    @InvocableMethod(label='Execute Static Code Analysis' description='Execute Static Code Analysis for given credential')
    global static void execute(List<InvocableVariables> variables) {
        CredentialsButtonsHandler.callNecessaryOperation(variables[0].credentialId, CredentialsButtonsHandler.STATIC_CODE_ANALYSIS);
    }
}