/**
 * This controller is used to show actual credits, reset api key and see transactions
 */
@SuppressWarnings('PMD')
public with sharing class appHome {
    // Not constants
    public List<copadoTransaction> transactionsList;
    public List<Feature__c> featuresList { get; set; }
    public Map<String, Object> registerMessages { get; set; }
    public String registry { get; set; }
    public void setRegistry(String msg) {
        registry = msg;
    }
    public String getRegistry() {
        return registry;
    }
    public String instanceLabel;
    public String defaultServerUrlName {
        get {
            Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
            if (orgDefaultSetting.Server_URL__c != null) {
                List<Copado_Cloud_Regional_Instances__mdt> instance = [
                    SELECT Label
                    FROM Copado_Cloud_Regional_Instances__mdt
                    WHERE value__c = :orgDefaultSetting.Server_URL__c
                    LIMIT 1
                ];
                return instance != null && instance.size() > 0 ? instance.get(0).Label : orgDefaultSetting.Server_URL__c + ' (Custom)';
            } else {
                return '';
            }
        }
        set;
    }

    public String customInstanceUrl { get; set; }
    public Boolean isCustomUrlSelected {
        get {
            return isCustomUrlSelected == null ? false : isCustomUrlSelected;
        }
        private set;
    }
    Map<String, String> cloudInstanceUrlMap = new Map<String, String>();
    public List<SelectOption> cloudInstances {
        get {
            if (cloudInstances == null) {
                cloudInstances = getCopadoCloudInstances();
            }
            return cloudInstances;
        }
        set;
    }
    public List<copadoTransaction> transactions {
        get {
            if (transactions == null) {
                transactions = getTransactions();
            }
            return transactions;
        }
        set;
    }
    public Boolean isApplicationRegistered {
        get {
            Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();
            return String.isNotBlank(orgDefaultSetting.CryptoKEY__c);
        }
        set;
    }

    public String defaultServerUrl { get; set; }
    @TestVisible
    private String responseBody;
    public Boolean canToggleVlocity {
        get {
            return FeatureManagement.checkPermission(ENABLE_VLOCITY_INTEGRATION);
        }
    }

    // Constants
    private final String DEPLOYMENTID = 'deploymentId';
    private final String USERID = 'userId';
    private final String JOBID = 'jobId';
    private final String UTF8 = 'UTF-8';
    private final String DIFF = 'diff';
    private final String BACKUP = 'backup';
    private final String TEST = 'test';
    private final String FILEDIFF = 'fileDiff';
    private final String BUILDTASK = 'buildTask';
    private final String VLOCITY = 'Vlocity';
    private final String ENABLE_VLOCITY_INTEGRATION = 'Enable_Vlocity_Integration';

    /**
     * wrapper class
     */
    public class copadoTransaction {
        public String userName { get; set; }
        public String deployment { get; set; }
        public String stepName { get; set; }
        public String job { get; set; }
        public String destinationOrg { get; set; }
        public String ddate { get; set; }
        public Integer credits { get; set; }
        public Decimal minutes { get; set; }
    }

    /**
     * Construction
     */
    public appHome() {
        transactionsList = new List<copadoTransaction>();
        featuresList = Feature__c.getAll().values();
        this.registerMessages = new Map<String, String>();
    }

    /**
     * This method is used to retrieve transactions by doing callout to "Settings.server_url + '/?transactions=true'" endpoint
     * Note: If user didn't complete the setup process, it should never run
     *
     * @return List of copadoTransaction wrapper class
     */
    public List<copadoTransaction> getTransactions() {
        List<Org__c> validatedOrgList = new List<Org__c>();
        String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        if (Schema.SObjectType.Deployment__c.isQueryable() && Schema.SObjectType.Deployment__c.isAccessible()) {
            validatedOrgList = [SELECT Id FROM Org__c WHERE Validated_Date__c != NULL AND SFDC_Org_ID__c = :orgId LIMIT 1];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Org__c.getLabel());
            return null;
        }

        transactionsList = new List<copadoTransaction>();

        // else is not needed because we are already showing message at creditsCompController related to this
        if (!validatedOrgList.isEmpty()) {
            try {
                Http cHttp = new Http();
                HttpRequest req = new HttpRequest();
                DeployAPI.setAuthHeaders(req); //to authenticate against heroku servers
                req.setEndpoint(Settings.server_url + '/?transactions=true');
                req.setMethod('GET');
                HttpResponse res = cHttp.send(req);
                //if response code is 401 return;
                if (res.getStatusCode() == 401) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Session_Has_Expired));
                    return null;
                }
                Map<String, Object> transactiosnFullMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> obj_transactions = (List<Object>) transactiosnFullMap.get('transactions');

                if (obj_transactions.isEmpty()) {
                    return null;
                }

                Set<Id> deploySet = new Set<Id>();
                Set<Id> ownerIdSet = new Set<Id>();

                for (Object obj : obj_transactions) {
                    Map<String, Object> tmp = (Map<String, Object>) obj;
                    try {
                        if (tmp.get(DEPLOYMENTID) != null && String.isNotBlank((String) tmp.get(DEPLOYMENTID))) {
                            deploySet.add((String) tmp.get(DEPLOYMENTID));
                        }
                        if (tmp.get(USERID) != null && String.isNotBlank((String) tmp.get(USERID))) {
                            ownerIdSet.add((String) tmp.get(USERID));
                        }
                    } catch (Exception ex) {
                        UIDesignHelper.catchExceptionMessage(ex);
                    }
                }
                Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c>();
                if (Schema.SObjectType.Deployment__c.isQueryable() && Schema.SObjectType.Deployment__c.isAccessible()) {
                    deploymentMap = new Map<Id, Deployment__c>([SELECT Id, Name, OwnerId FROM Deployment__c WHERE Id IN :deploySet LIMIT 10000]);
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment__c.getLabel());
                    return null;
                }
                for (Deployment__c dep : deploymentMap.values()) {
                    ownerIdSet.add(dep.OwnerId);
                }
                Map<Id, User> userMap = new Map<Id, User>();
                if (Schema.SObjectType.User.isQueryable() && Schema.SObjectType.User.isAccessible()) {
                    userMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :ownerIdSet LIMIT 10000]);
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User.getLabel());
                    return null;
                }
                Map<Id, Deployment_Job__c> jobMap = new Map<Id, Deployment_Job__c>();
                if (Schema.SObjectType.Deployment_Job__c.isQueryable() && Schema.SObjectType.Deployment_Job__c.isAccessible()) {
                    jobMap = new Map<Id, Deployment_Job__c>(
                        [
                            SELECT Id, Name, Step__r.Name, Step__r.Deployment__c, Destination_Org__r.To_Org_Name__c
                            FROM Deployment_Job__c
                            WHERE Step__r.Deployment__c IN :deploySet
                            LIMIT 20000
                        ]
                    );
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Job__c.getLabel());
                    return null;
                }

                for (Object obj : obj_transactions) {
                    Map<String, Object> tmp = (Map<String, Object>) obj;
                    copadoTransaction ct = new copadoTransaction();
                    try {
                        ct.userName = userMap.get((String) tmp.get(USERID)).Name;
                    } catch (Exception ex) {
                        ct.userName = '';
                    }
                    ct.credits = (Integer) tmp.get('credits');
                    ct.minutes = (Decimal) tmp.get('minutes');
                    if (ct.credits < 0 || ct.minutes < 0) {
                        if (ct.credits < 0) {
                            try {
                                ct.deployment = deploymentMap.get((String) tmp.get(DEPLOYMENTID)).Name;
                            } catch (Exception ex) {
                                ct.deployment = Label.RECORD_DELETED;
                            }
                        }
                        if (ct.credits < 0) {
                            try {
                                ct.job = jobMap.get((String) tmp.get(JOBID)).Name;
                            } catch (Exception ex) {
                                ct.job = Label.RECORD_DELETED;
                            }
                        }
                        if (ct.credits < 0) {
                            try {
                                ct.destinationOrg = jobMap.get((String) tmp.get(JOBID)).Destination_Org__r.To_Org_Name__c;
                            } catch (Exception ex) {
                                ct.destinationOrg = Label.RECORD_DELETED;
                            }
                        }
                        if (ct.credits < 0) {
                            try {
                                ct.stepName = jobMap.get((String) tmp.get(JOBID)).Step__r.Name;
                            } catch (Exception ex) {
                                ct.stepName = Label.RECORD_DELETED;
                            }
                        }
                        ct.ddate = (String) tmp.get('date');
                        String action = tmp.get('stepType') + '';
                        if (action != null && (action == DIFF || action == BACKUP || action == TEST || action == FILEDIFF || action == BUILDTASK)) {
                            String descrip = action == DIFF
                                ? OrgDiff__c.SObjectType.getDescribe().getLabel()
                                : action == TEST
                                      ? Apex_Test_Result__c.SObjectType.getDescribe().getLabel()
                                      : action == BACKUP
                                            ? Git_Backup__c.SObjectType.getDescribe().getLabel()
                                            : action == FILEDIFF
                                                  ? Snapshot_Difference__c.SObjectType.getDescribe().getLabel()
                                                  : action == BUILDTASK ? Build_Task__c.SObjectType.getDescribe().getLabel() : action;

                            ct.deployment = Label.Action_Performed_Was + ' ' + descrip;
                            ct.job = '';
                            ct.destinationOrg = '';
                            ct.stepName = '';
                        }
                        if (ct.minutes < 0) {
                            ct.deployment = Label.Action_Performed_Was + ' ' + Label.Selenium_Testing;
                            ct.job = '';
                            ct.destinationOrg = '';
                            ct.stepName = '';
                        }
                        transactionsList.add(ct);
                    }
                }
            } catch (Exception ex) {
                UIDesignHelper.catchExceptionMessage(ex);
            }
        }
        return transactionsList;
    }

    /**
     * This is used to create or reset API key
     */
    public void createAPIKey() {
        try {
            responseBody = DeployAPI.createAPIKeys();
        } catch (Exception ex) {
            UIDesignHelper.catchExceptionMessage(ex);
        }
    }

    /**
     * This is used to update API key to the custom setting
     */
    public void updatePrivateSettings() {
        try {
            Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            String key = (String) mapa.get('api_key');
            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            ps.API_Key__c = DeployAPI.encryptAPIKey(key);
            Utilities.Secure_DML(ps, Utilities.DML_Action.UPS, schema.SObjectType.Personal_Settings__c);
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.CONFIRM, Label.API_KEY + ' ' + Label.Created);
        } catch (Exception ex) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.API_CREATION_ERROR);
        }
    }

    /**
     * This is used to show existing api key
     *
     * @return String: API key value
     */
    public String getAPIKey() {
        try {
            return new MaskApiKey(DeployAPI.getUserAPIKey(true)).execute();
        } catch (Exception ex) {
            // Silently skypped since this error should never happen and is a super edge case
            System.debug('User API KEY encrypted with invalid Org Crypto Key');
            UIDesignHelper.catchExceptionMessage(ex);
            return null;
        }
    }

    /**
     * classic getter for the <a> tag (custom url)
     *
     * @return
     */
    public PageReference getLinkCstBindExtensionToOrg() {
        String apiKey = DeployAPI.getUserAPIKey();
        if (apiKey == null) {
            apiKey = '';
        }
        String url = 'copado:setupext/' + EncodingUtil.urlEncode(apiKey, UTF8) + '/' + EncodingUtil.urlEncode(UserInfo.getOrganizationName(), UTF8);
        PageReference pRef = new PageReference(url);
        return pRef;
    }

    /**
     * non-classic action (which does not allow <a> tags for custom urls)
     *
     * @return
     */
    public PageReference cstBindExtensionToOrg() {
        return getLinkCstBindExtensionToOrg();
    }

    /**
     * This is used to enable or disable Vlocity Feature in the organization
     */

    public void vlocityFeatureOperations() {
        Feature__c vlocityFeature = getVlocityFeature();

        if (vlocityFeature == null) {
            vlocityFeature = new Feature__c(Name = VLOCITY, Enabled__c = true, Quantity__c = 1);
            insert vlocityFeature;
        } else {
            vlocityFeature.Enabled__c = !vlocityFeature.Enabled__c;
            vlocityFeature.Quantity__c = vlocityFeature.Enabled__c ? 1 : 0;
            update vlocityFeature;
        }

        // updating the list from scratch to render on the page correctly
        featuresList.clear();
        featuresList = Feature__c.getAll().values();
    }

    /**
     * This is used to check the Vlocity feature in the organization
     */
    public Feature__c getVlocityFeature() {
        Feature__c vlocityFeature = Feature__c.getAll().get(VLOCITY);
        return vlocityFeature;
    }

    /**
     * Refresh features in all Customer's Copado Installations (Sandboxes, Dev Orgs)
     * @see RefreshCopadoInstallationWrapper
     * @see DeployAPI
     */
    public void refreshFeatures() {
        try {
            // sync vlocity and on premise deployment as well, that is why we set parameter as true
            RefreshFeatures.Request request = new RefreshFeatures.Request();
            request.syncOnPremiseDeployer = true;
            request.syncVlocity = true;
            List<RefreshFeatures.Response> responses = RefreshFeatures.execute(new List<RefreshFeatures.Request>{ request });
            UIDesignHelper.genericWarningMessage(responses[0].success ? ApexPages.Severity.CONFIRM : ApexPages.Severity.ERROR, responses[0].message);
        } catch (Exception ex) {
            UIDesignHelper.catchExceptionMessage(ex);
        }
    }

    public void setRemoteSite() {
        // Create Remote site settings
        registerMessages.put('RemoteSiteSetting', RegisterCopado.createRemoteSite(instanceLabel, defaultServerUrl));
        registry = JSON.serialize(registerMessages);
    }

    public void setNamedCredential() {
        // Create named credentials
        if (!String.isBlank(registry)) {
            registerMessages = (Map<string, object>) JSON.deserializeUntyped(registry);
        }

        if (registerMessages.containsKey('RemoteSiteSetting') && registerMessages.get('RemoteSiteSetting') == 'Success') {
            registerMessages.put('NamedCredential', RegisterCopado.createNamedCredential(instanceLabel, defaultServerUrl));
            registry = JSON.serialize(registerMessages);
        }
    }

    public void registerBackend() {
        //Register Copado
        if (!String.isBlank(registry)) {
            registerMessages = (Map<string, object>) JSON.deserializeUntyped(registry);
        }

        if (registerMessages.containsKey('NamedCredential') && registerMessages.get('NamedCredential') == 'Success') {
            RegisterCopado.setUpCopadoRegistration();
            // update named credentials
            RegisterCopado.populateNamedCredentials(instanceLabel);
        } else if (!String.isBlank(registry)) {
            RegisterCopado.handleRollBack(registry);
        }
    }

    public PageReference registerCopado() {
        if (defaultServerUrl != null && defaultServerUrl != 'None') {
            instanceLabel = cloudInstanceUrlMap.get(defaultServerUrl);
            if (isCustomUrlSelected) {
                defaultServerUrl = this.customInstanceUrl;
                instanceLabel = 'Copado_CustomURL';
            }
            // update custom settings
            RegisterCopado.setDefaultSettings(defaultServerUrl);
            return null;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.registrationError));
        }
        return null;
    }

    public List<SelectOption> getCopadoCloudInstances() {
        List<SelectOption> cloudInstances = new List<SelectOption>();
        cloudInstances.add(new SelectOption('None', '-- None --'));
        for (Copado_Cloud_Regional_Instances__mdt instance : [SELECT Label, DeveloperName, value__c FROM Copado_Cloud_Regional_Instances__mdt]) {
            cloudInstances.add(new SelectOption(instance.value__c, instance.Label));
            cloudInstanceUrlMap.put(instance.value__c, instance.DeveloperName);
        }
        cloudInstances.add(new SelectOption('Copado_CustomURL', 'Custom URL'));
        return cloudInstances;
    }

    public PageReference setCloudInstanceURL() {
        if (defaultServerUrl != null && defaultServerUrl == 'Copado_CustomURL') {
            this.isCustomUrlSelected = true;
        }
        return null;
    }
    public Boolean hasError {
        get {
            return ApexPages.hasMessages();
        }
    }
}