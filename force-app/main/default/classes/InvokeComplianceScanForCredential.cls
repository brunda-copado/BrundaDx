global with sharing class InvokeComplianceScanForCredential {
    global with sharing class InvocableVariables {
        @InvocableVariable(label='Credential Id' required=true)
        global Id credentialId;
    }

    @InvocableMethod(label='Execute Compliance Scan' description='Execute Compliance Scan for given credential')
    global static void execute(List<InvocableVariables> variables) {
        CredentialsButtonsHandler.callNecessaryOperation(variables[0].credentialId, CredentialsButtonsHandler.COMPLIANCE_HUB);
    }
}