public with sharing class CredentialRedirectionHandler {
    @AuraEnabled
    public static String createDoOauthAndReturnApiURL(String credentialId) {
        String oauthURL = '';
        if (String.isNotBlank(credentialId)) {
            String apiURL = EncodingUtil.urlEncode(
                [SELECT API_URL__c FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED]
                .API_URL__c,
                'UTF-8'
            );

            Org__c credential = [SELECT Id, Org_Type__c, Custom_Domain__c FROM Org__c WHERE Id = :credentialId];
            String urlParameters = '?orgId=' + EncodingUtil.urlEncode(credentialId, 'UTF-8') + '&url=' + apiURL;
            if (
                credential.Org_Type__c == 'Sandbox' ||
                (String.isNotBlank(credential.Org_Type__c) && credential.Org_Type__c.startsWithIgnoreCase('Scratch Org'))
            ) {
                urlParameters += '&sandbox=true';
            }
            if (credential.Org_Type__c == 'Custom Domain') {
                urlParameters += '&domain=' + EncodingUtil.urlEncode(credential.Custom_Domain__c, 'UTF-8');
            }
            urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(), 'UTF-8');
            urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(UserInfo.getUserId(), 'UTF-8');
            urlParameters +=
                '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(UserInfo.getOrganizationId() + UserInfo.getUserId()), 'UTF-8');
            String herokuServer = Settings.server_url;
            String urlOauth = herokuServer + '/Authorize/sforceLogin' + urlParameters;
            PageReference pReference = new PageReference(urlOauth);
            oauthURL = pReference.getURL();
        }
        return oauthURL;
    }

    @AuraEnabled
    public static String createOpenOrgURL(String credentialId) {
        String openOrgPageURL = '';
        PageReference pReference = Page.ScratchOrgOpen;
        if (String.isNotBlank(credentialId)) {
            pReference.getParameters().put('id', credentialId);
        }
        pReference.setRedirect(true);
        openOrgPageURL = pReference.getURL();
        return openOrgPageURL;
    }

    @AuraEnabled
    public static String createDXOperationPageURL(String credentialId) {
        String openDXOperrationPageURL = '';
        PageReference pReference = Page.DXOperation;
        if (String.isNotBlank(credentialId)) {
            pReference.getParameters().put('id', credentialId);
        }
        pReference.setRedirect(true);
        openDXOperrationPageURL = pReference.getURL();
        return openDXOperrationPageURL;
    }
}