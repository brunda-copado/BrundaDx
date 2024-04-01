@SuppressWarnings('PMD')
public with sharing class Settings {
    public static final Decimal DEFAULT_MAX_VOLUME_SIZE = 10;
    public static final String DEFAULT_COPADO_SITE = 'https://copado.secure.force.com';
    public static final String DEFAULT_SERVER_URL = 'https://na.api.copado.com';
    public static final String DEFAULT_FUNCTIONS_NAMED_CREDENTIAL = 'mc_backend';
    public static final String DEFAULT_NAMESPACE = 'copado__';
    public static final String NONE = 'none';
    public static final String ORGANIZATION_URL = URL.getSalesforceBaseUrl().toExternalForm();
    public static final String USER_ID = UserInfo.getUserId();
    public static final String ORGANIZATION_ID = UserInfo.getOrganizationId();

    public static final Integer MIN_VOLUME_TTL = 10;
    public static final Integer MAX_VOLUME_TTL = 1440;

    private static Settings__c defaultsetting = Settings__c.getOrgDefaults();

    /**
     * copado force site for oauth callback
     */
    public static String copado_site {
        get {
            if (copado_site == null) {
                copado_site = String.isNotBlank(defaultsetting.Copado_Site__c) ? defaultsetting.Copado_Site__c : DEFAULT_COPADO_SITE;
            }
            return copado_site;
        }
        private set;
    }

    /**
     * Heroku server URL
     */
    public static String server_url {
        get {
            if (server_url == null) {
                server_url = String.isNotBlank(defaultsetting.Server_URL__c) ? defaultsetting.Server_URL__c : DEFAULT_SERVER_URL;
            }
            return server_url;
        }
        private set;
    }

    public static Decimal maximumVolumeSize {
        get {
            if (maximumVolumeSize == null) {
                maximumVolumeSize = defaultsetting.MaximumVolumeSize__c != null ? defaultsetting.MaximumVolumeSize__c : DEFAULT_MAX_VOLUME_SIZE;
            }
            return maximumVolumeSize;
        }
        private set;
    }

    public static String functionsNamedCredential {
        get {
            if (functionsNamedCredential == null) {
                functionsNamedCredential = String.isNotBlank(defaultsetting.Functions_Named_Credential__c)
                    ? defaultsetting.Functions_Named_Credential__c
                    : DEFAULT_FUNCTIONS_NAMED_CREDENTIAL;
            }
            return functionsNamedCredential;
        }
        private set;
    }
    /**
     * Copado App Namespace
     */
    public static String ns {
        get {
            if (ns == null) {
                ns = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1 ? 'copado__' : '';
            }
            return ns;
        }
        private set;
    }

    /**
     * This attribute contains the session Id and the url parameter for heroku api calls
     */
    public static String generic_heroku_params = '?nosid=1';

    public static Boolean scalable_grid_enabled {
        get {
            if (scalable_grid_enabled == null) {
                scalable_grid_enabled = false;
                try {
                    scalable_grid_enabled = [
                        SELECT Id, DeveloperName, MasterLabel, Enabled__c
                        FROM Copado_Setting__mdt
                        WHERE DeveloperName = 'Big_Metadata'
                        LIMIT 1
                    ]
                    .Enabled__c;
                } catch (Exception e) {
                    System.debug(e.getMessage());
                }
            }
            return scalable_grid_enabled;
        }
        private set;
    }

    public static String toolingApiVersion {
        get {
            return '53.0';
        }
        private set;
    }

    public String maskedApiKey {
        get {
            if (maskedApiKey == null) {
                maskedApiKey = new MaskApiKey(DeployAPI.getUserAPIKey()).usingPlaceholder().execute();
            }
            return maskedApiKey;
        }
        private set;
    }

    public String herokuServer { get; set; }
    public String urlParameters { get; set; }
    public String urlBase { get; set; }
    public String namespace { get; set; }
    public Boolean scalableGrid { get; set; }
    public Personal_Settings__c mySettings { get; set; }

    /**
     * This is set only in User Story VF
     */
    public SObject userStoryObj { get; set; }

    // CONSTRUCTOR

    public Settings(ApexPages.StandardController ext) {
        constructor();
    }

    public Settings(GitCommitLookupController controller) {
        constructor();
    }

    public Settings(GitCommitChangesController controller) {
        constructor();
    }

    public Settings(webhookLookupController controller) {
        constructor();
    }

    public Settings(ScratchOrgStatusCtrl controller) {
        constructor();
    }

    public Settings(ScratchOrgMetadataController contoller) {
        constructor();
    }

    public Settings(ArtifactManageMetadataController contoller) {
        constructor();
    }

    public Settings(ScratchOrgDisplayController contoller) {
        constructor();
    }

    public Settings(ManageGitBranchesCntr contoller) {
        constructor();
    }

    public Settings(DXOperationController contoller) {
        constructor();
    }

    public Settings(ManageRepositoryBranchesController controller) {
        constructor();
    }

    public Settings(GitCommit_OperationsController controller) {
        constructor();
    }

    public Settings(GitCommit_GridController controller) {
        constructor();
    }

    public Settings(WorkSubmitService controller) {
        constructor();
    }

    public Settings(ResolveConflictsController controller) {
        constructor();
    }

    public Settings() {
        constructor();
    }

    // PUBLIC

    public String getUserStoryAsJSON() {
        return JSON.serialize(this.userStoryObj);
    }

    public static String getCurrentUserLicenses() {
        return JSON.serialize(getCurrentUserLicensesObject());
    }

    public static LicenseWrapper getCurrentUserLicensesObject() {
        return new licenseWrapper(
            LicenseHelper.isCopadoEnabled(),
            LicenseHelper.isCCMEnabled(),
            LicenseHelper.isCSTEnabled(),
            LicenseHelper.isCADEnabled(),
            LicenseHelper.isCCHEnabled(),
            LicenseHelper.isMultiLicense()
        );
    }

    // PRIVATE

    private void constructor() {
        getOrgMetdataTypes();
        urlParameters = Settings.generic_heroku_params;
        herokuServer = Settings.server_url;
        urlBase = server_url + '/json/v1/';
        scalableGrid = Settings.scalable_grid_enabled;
        namespace = Settings.ns;
        mySettings = Personal_Settings__c.getInstance();
        if (mySettings == null) {
            mySettings = new Personal_Settings__c(SetupOwnerId = UserInfo.getUserId());
        }
        mySettings.API_Key__c = DeployAPI.decryptAPIKey(mySettings.API_Key__c);
    }

    private void getOrgMetdataTypes() {
        Map<String, String> getOrgMetaTypesMap = new Map<String, String>();
        if (ApexPages.currentPage() != null) {
            getOrgMetaTypesMap.putAll(ApexPages.currentPage().getParameters());
        }
        String orgId = getOrgMetaTypesMap.get('orgId');
        if (!String.isBlank(orgId)) {
            Org__c org = Utilities.getOrgById(orgId);
            if (String.isNotBlank(org.Metadata_Types__c)) {
                Settings.generic_heroku_params += '&filter=' + EncodingUtil.urlEncode(org.Metadata_Types__c, 'UTF-8');
            }
        }
    }

    // INNER

    public class LicenseWrapper {
        public Boolean hasCopado { get; set; }
        public Boolean hasCCM { get; set; }
        public Boolean hasCST { get; set; }
        public Boolean hasCAD { get; set; }
        public Boolean hasCCH { get; set; }
        public Boolean hasMultiLicense { get; set; }
        public licenseWrapper(Boolean hasCopado, Boolean hasCCM, Boolean hasCST, Boolean hasCAD, Boolean hasCCH, Boolean hasMultiLicense) {
            this.hasCopado = hasCopado;
            this.hasCCM = hasCCM;
            this.hasCST = hasCST;
            this.hasCAD = hasCAD;
            this.hasCCH = hasCCH;
            this.hasMultiLicense = hasMultiLicense;
        }
    }
}