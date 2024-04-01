global inherited sharing class RegisterCopado {
    private static final String DEFAULT_COPADO_NAMESPACE = 'copado__';
    private static final Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();

    global RegisterCopado() {
        throw new InvalidInstantiationException();
    }

    /**
     * The parameter is given to be able to extend the settings usage in the future since global methods cannot change their parameters
     * copadoSettings is a general name but for now we are only getting ServerUrl
     */
    global static void setDefaultSettings(final String copadoSettings) {
        populateDefaultSettings(copadoSettings);
    }

    /**
     * This logic will only affect Trial Orgs for now, where PostInstallClass is not executed by default
     * since for Copado normal installations, default Settings__c record is created with its default values in PostInstallClass
     * TODO: remove default field values for Settings__c default record
     */
    public static void populateDefaultSettings(final String serverUrl) {
        if (String.isBlank(orgDefaultSetting.Namespace__c)) {
            orgDefaultSetting.Namespace__c = DEFAULT_COPADO_NAMESPACE;
        }
        orgDefaultSetting.Server_URL__c = serverUrl;
        upsert orgDefaultSetting;
    }

    public static void populateNamedCredentials(final String namedCredentials) {
        orgDefaultSetting.Functions_Named_Credential__c = namedCredentials;
        upsert orgDefaultSetting;
    }

    global static void setUpCopadoRegistration() {
        // We call the registerDefaultCryptoKey from here instead of making it global since
        // otherwise we could not change it in the future if for example, we need to add a parameter
        registerDefaultCryptoKeyAndVersion(null, null);
    }

    global static void setUpCopadoRegistration(String serverUrl) {
        String instanceLabel = getCopadodCloudInstances().get(serverUrl) != null ? getCopadodCloudInstances().get(serverUrl) : 'Copado_CustomURL';
        createRemoteSite(instanceLabel, serverUrl);
        createNamedCredential(instanceLabel, serverUrl);
        registerDefaultCryptoKeyAndVersion(null, serverUrl);
        RegisterCopado.setDefaultSettings(serverUrl);
    }

    private static Map<String, String> getCopadodCloudInstances() {
        Map<String, String> cloudInstanceUrlMap = new Map<String, String>();
        for (Copado_Cloud_Regional_Instances__mdt instance : [SELECT Label, DeveloperName, value__c FROM Copado_Cloud_Regional_Instances__mdt]) {
            cloudInstanceUrlMap.put(instance.value__c, instance.DeveloperName);
        }
        return cloudInstanceUrlMap;
    }

    /**
     * This method is being called from PostInstallClass class to update currentversion in the bacekdend by doing a callout
     */
    @Future(Callout=true)
    public static void updatePackageVersion(String version) {
        registerDefaultCryptoKeyAndVersion(version, null);
    }

    /**
     * Crypto key is retrieved, or generated and saved to send it to the backend server in order to
     * be used when storing and reading sensitive information like github passwords
     */
    private static void registerDefaultCryptoKeyAndVersion(final String version, final String serverUrl) {
        final String key = getKey();
        try {
            final Map<String, Object> parsedResponse = doCallout(key, version, serverUrl);
            if (isResponseSuccessful(parsedResponse)) {
                upsertDefaultCryptoKey(key);
            } else {
                handleRollBack(null);
            }
        } catch (Exception e) {
            handleRollBack(null);
            addPageMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.registrationError));
        }
    }

    public static void handleRollBack(String errorMsgs) {
        // Rollback changes
        try {
            Map<String, Object> mapErrorMsgs = new Map<String, Object>();
            if (!String.isBlank(errorMsgs)) {
                mapErrorMsgs = (Map<String, Object>) JSON.deserializeUntyped(errorMsgs);
            }
            handleServiceOperations(errorMsgs, mapErrorMsgs);
            for (String s : mapErrorMsgs.keySet()) {
                String msg = (String) mapErrorMsgs.get(s);
                if (msg.contains('INSUFFICIENT_ACCESS: Access from current IP address is not allowed')) {
                    addPageMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.registrationAccessError));
                } else {
                    addPageMessage(new ApexPages.Message(ApexPages.Severity.ERROR, (String) mapErrorMsgs.get(s)));
                }
            }
        } catch (Exception e) {
            addPageMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.registrationError));
        }
    }

    private static void handleServiceOperations(String errorMsgs, Map<String, Object> mapErrorMsgs) {
        // Metadata Service
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();

        // Delete Remote Site Settings
        if (String.isBlank(errorMsgs) || (mapErrorMsgs.containsKey('RemoteSiteSetting') && mapErrorMsgs.get('RemoteSiteSetting') == 'Success')) {
            service.deleteMetadata('RemoteSiteSetting', new List<String>{ orgDefaultSetting.Functions_Named_Credential__c });
        }
        // Delete Named Credentials
        if (String.isBlank(errorMsgs) || (mapErrorMsgs.containsKey('NamedCredential') && mapErrorMsgs.get('NamedCredential') == 'Success')) {
            service.deleteMetadata('NamedCredential', new List<String>{ orgDefaultSetting.Functions_Named_Credential__c });
        }
        // update Custom Settings
        orgDefaultSetting.Server_URL__c = null;
        orgDefaultSetting.Functions_Named_Credential__c = null;
        update orgDefaultSetting;
    }

    private static String getKey() {
        return String.isBlank(orgDefaultSetting.CryptoKEY__c)
            ? EncodingUtil.base64Encode(Crypto.generateAesKey(256))
            : orgDefaultSetting.CryptoKEY__c;
    }

    private static Map<String, Object> doCallout(final String key, final String version, final String serverUrl) {
        final String endpoint = getRequestEndpoint(orgDefaultSetting.Server_URL__c != null ? orgDefaultSetting.Server_URL__c : serverUrl);
        final String currentCopadoVersion = version != null ? version : orgDefaultSetting.Current_Copado_Version__c;
        final LogKey logKeyInstance = new LogKey(key, currentCopadoVersion);

        return (Map<String, Object>) new HerokuCallout(endpoint, HttpMethod.POST)
            .useDeprecatedKey()
            .default()
            .body(logKeyInstance)
            .request()
            .parseResponse();
    }

    private static String getRequestEndpoint(final String serverUrl) {
        return serverUrl + '/json/v1/registerKey';
    }

    private static Boolean isResponseSuccessful(final Map<String, Object> parsedResponse) {
        final Boolean isSuccess = Boolean.valueOf(parsedResponse.get('isSuccess'));
        final Boolean isFinished = Boolean.valueOf(parsedResponse.get('isFinished'));
        return isSuccess && isFinished;
    }

    private static void upsertDefaultCryptoKey(final String key) {
        if (String.isBlank(orgDefaultSetting.CryptoKEY__c)) {
            orgDefaultSetting.CryptoKEY__c = key;
            upsert orgDefaultSetting;
        }
        addPageMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Copado_Application_Registered_Successfully));
    }

    private static void addPageMessage(final ApexPages.Message message) {
        if (ApexPages.currentPage() != null) {
            ApexPages.addMessage(message);
        }
    }

    public static String createRemoteSite(String fullName, String url) {
        //Metadata Service
        try {
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            service.SessionHeader = new MetadataService.SessionHeader_element();
            service.SessionHeader.sessionId = UserInfo.getSessionId();
            //Metadata for remote site settings
            MetadataService.RemoteSiteSetting remoteSiteSettings = new MetadataService.RemoteSiteSetting();
            remoteSiteSettings.fullName = fullName;
            remoteSiteSettings.url = url;
            remoteSiteSettings.description = 'Remote site settings created from registertion of copado';
            remoteSiteSettings.isActive = true;
            remoteSiteSettings.disableProtocolSecurity = false;
            MetadataService.SaveResult[] results = service.createMetadata(new List<MetadataService.Metadata>{ remoteSiteSettings });
            for (MetadataService.SaveResult result : results) {
                if (result.success) {
                    return 'Success';
                } else {
                    addPageMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result.errors[0].message));
                    return result.errors[0].message;
                }
            }
        } catch (Exception e) {
            return e.getMessage();
        }

        return 'Success';
    }

    public static String createNamedCredential(String fullName, String url) {
        try {
            //Metadata Service
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            service.SessionHeader = new MetadataService.SessionHeader_element();
            service.SessionHeader.sessionId = UserInfo.getSessionId();
            MetadataService.NamedCredential credential = new MetadataService.NamedCredential();
            credential.fullName = fullName;
            credential.label = fullName;
            credential.endpoint = url;
            credential.principalType = 'NamedUser';
            credential.protocol = 'NoAuthentication';
            credential.allowMergeFieldsInHeader = true;
            credential.generateAuthorizationHeader = false;
            MetadataService.SaveResult[] results = service.createMetadata(new List<MetadataService.Metadata>{ credential });
            for (MetadataService.SaveResult result : results) {
                if (result.success) {
                    // upsert customs settings function name
                    orgDefaultSetting.Functions_Named_Credential__c = fullName;
                } else {
                    addPageMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result.errors[0].message));
                    return result.errors[0].message;
                }
            }
        } catch (Exception e) {
            return e.getMessage();
        }

        return 'Success';
    }

    private class LogKey {
        private final String key;
        private final String copadoVersion;

        public LogKey(String key, String copadoVersion) {
            this.key = key;
            this.copadoVersion = copadoVersion;
        }
    }

    private class InvalidInstantiationException extends Exception {
    }
}