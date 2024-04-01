public with sharing class AuthGrantService implements CLIInterface {

    public CLIInterface getInstance() {
        return new AuthGrantService();
    }

    public String run(CliProxy.CLIWrapper record) {
        AuthGrantWrapper newCopadoScratchOrgInfo= (AuthGrantWrapper) JSON.deserialize(record.body, AuthGrantWrapper.class);
        Id environmentId= getEnvironment(newCopadoScratchOrgInfo.scratchOrgId);
        List<Org__c> devHubCopado = getDevHubCopado(newCopadoScratchOrgInfo);

        checkScrathcOrgInfo(devHubCopado, newCopadoScratchOrgInfo);
        
        Id scratchOrgId;
        Savepoint sp;
        try {
            if (!Test.isRunningTest()) {
                sp = Database.setSavepoint();
            }
            if (String.isBlank(environmentId)) {
                Environment__c newScratchOrgEnvironment = new Environment__c();
                newScratchOrgEnvironment.Name = newCopadoScratchOrgInfo.environmentName;
                newScratchOrgEnvironment.Org_ID__c = newCopadoScratchOrgInfo.scratchOrgId;
                newScratchOrgEnvironment.Type__c = 'Scratch Org';
                DML.safeInsert(newScratchOrgEnvironment, 'Could not create an Environment object on the Auth Grant Service ( AuthGrantService.run class )');
                environmentId = newScratchOrgEnvironment.Id;
            }

            Org__c newCopadoScratchOrg = new Org__c();
            newCopadoScratchOrg.Environment__c = environmentId;
            newCopadoScratchOrg.Name = newCopadoScratchOrgInfo.environmentName;
            newCopadoScratchOrg.Username__c = newCopadoScratchOrgInfo.scratchOrgUserName;
            newCopadoScratchOrg.Org_Type__c = 'Scratch Org';
            newCopadoScratchOrg.Developer_Hub_Org__c = devHubCopado[0].Id;
            newCopadoScratchOrg.Scratch_Org_Status__c = 'Active';
            newCopadoScratchOrg.Validated_Date__c = System.now(); 
            newCopadoScratchOrg.Scratch_Org_Expiration_Date__c = getDate(newCopadoScratchOrgInfo.scratchOrgExpirationDate);
            newCopadoScratchOrg.SFDC_Org_ID__c = newCopadoScratchOrgInfo.scratchOrgId + '_' + UserInfo.getUserId();
            DML.safeInsert(newCopadoScratchOrg, 'Could not create a Credential object on the Auth Grant Service ( AuthGrantService.run class )');
            scratchOrgId = newCopadoScratchOrg.Id;

            Attachment authInfoAttachment = new Attachment();
            authInfoAttachment.Name = 'ScratchOrgExternal';
            authInfoAttachment.ParentId = scratchOrgId;
            authInfoAttachment.Body = Blob.valueOf(newCopadoScratchOrgInfo.authInfo);
            DML.safeInsert(authInfoAttachment, 'Could not create an Attachment object on the Auth Grant Service ( AuthGrantService.run class )');

            SfdxAPI.authorizeExternalScratchOrg(scratchOrgId, newCopadoScratchOrgInfo.authInfo);
        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                Database.rollback(sp);
            }
            throw new CliException(ex.getMessage());
        }

        return (JSON.serialize(new AuthGrantResultWrapper(environmentId, scratchOrgId)));
    }

    private List<Org__c> getDevHubCopado(AuthGrantWrapper scratchOrgInfo) {
        return [
            SELECT Id
            FROM Org__c
            WHERE
                Username__c = :scratchOrgInfo.devHubUserName
                AND Environment__r.Org_ID__c = :scratchOrgInfo.devHubOrgId
                AND is_Developer_Hub_Org__c = TRUE
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    private void checkScrathcOrgInfo(List<Org__c> devHubCopado, AuthGrantWrapper scratchOrgInfo) {
        if (devHubCopado.isEmpty()) {
            throw new CliException('Dev Hub does not exist');
        }
        if (existScratchOrg(scratchOrgInfo.scratchOrgId)) {
            throw new CliException('This ScratchOrg already Exists');
        }
        if (String.isBlank(scratchOrgInfo.authInfo)) {
            throw new CliException('There is no auth info for this ScratchOrg');
        }
    }

    private Boolean existScratchOrg(String scratchOrgId) {
        List<Org__c> newScratchOrg = [SELECT Id FROM Org__c WHERE SFDC_Org_ID__c = :scratchOrgId + '_' + UserInfo.getUserId() WITH SECURITY_ENFORCED];
        return !newScratchOrg.isEmpty();
    }

    private Id getEnvironment(String environmentId) {
        List<Environment__c> environment = [SELECT Id FROM Environment__c WHERE Org_ID__c = :environmentId WITH SECURITY_ENFORCED LIMIT 1];
        return environment.isEmpty() ? null : environment[0].Id;
    }

    private Date getDate(String textDate) {
        Date result;
        try {
            result = Date.valueOf(textDate);
        } catch(Exception ex) {
            System.debug(LoggingLevel.DEBUG, ex);
        }
        return result;
    }

    @TestVisible
    private class AuthGrantWrapper {
        public String environmentName;
        public String devHubOrgId;
        public String devHubUserName;
        public String scratchOrgUserName;
        public String scratchOrgId;
        public String scratchOrgExpirationDate;
        public String authInfo;
    }

    @TestVisible
    private class AuthGrantResultWrapper extends CliSfDataWrapper {
        public String environmentId;
        public String orgCredentialId;
        public AuthGrantResultWrapper(String environmentId, String orgCredentialId) {
            this.status = CliSfDataWrapper.StatusResult.OK.name();
            this.message = 'ScratchOrg Credential created';
            this.environmentId = environmentId;
            this.orgCredentialId = orgCredentialId;
        }
    }
}