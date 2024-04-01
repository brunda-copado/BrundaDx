@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RefreshFeatures {
    // GLOBAL

    global class Request {
        @InvocableVariable
        global Boolean syncVlocity;
        @InvocableVariable
        global Boolean syncOnPremiseDeployer;

        global Request() {
            this.syncVlocity = false;
            this.syncOnPremiseDeployer = false;
        }
    }

    global class Response {
        @InvocableVariable
        global String message;
        @InvocableVariable
        global Boolean success;
    }

    @InvocableMethod(label='Refresh Features' description='' category='Copado Application')
    global static List<Response> execute(List<Request> requests) {
        // this is mainly needed for playgrounds and QA
        Request request = requests[0];

        DeployAPI.HerokuResponse herokuResponse = execute(request.syncVlocity, request.syncOnPremiseDeployer);
        Response response = new Response();
        response.message = herokuResponse.message;
        response.success = herokuResponse.success;
        return new List<Response>{ response };
    }

    // PRIVATE

    private static DeployAPI.HerokuResponse execute(Boolean syncVlocity, Boolean syncOnPremiseDeployer) {
        // hard-coded features like the ones in DeployAPI.syncFeatures();  ***** Requested by Nahuel *****
        Integer eeLicensesInteger = FeatureManagement.checkPackageIntegerValue('EE_Licenses_Enabled');
        Integer cadLicensesInteger = FeatureManagement.checkPackageIntegerValue('CAD_Licenses_Enabled');
        Integer ccmLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCM_Licenses_Enabled');
        Integer cstLicensesInteger = FeatureManagement.checkPackageIntegerValue('CST_Licenses_Enabled');
        Integer cchLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCH_Licenses_Enabled');
        Integer cbmLicensesInteger = FeatureManagement.checkPackageIntegerValue('CBM_Branches');

        List<Feature__c> features = new List<Feature__c>();
        // hard-coded namespace, because backend is working with namespace even for dev orgs  ***** Requested by Nahuel *****
        features.add(new Feature__c(Name = 'copado__EE_Licenses_Enabled', Enabled__c = eeLicensesInteger > 0, Quantity__c = eeLicensesInteger));
        features.add(new Feature__c(Name = 'copado__CAD_Licenses_Enabled', Enabled__c = cadLicensesInteger > 0, Quantity__c = cadLicensesInteger));
        features.add(new Feature__c(Name = 'copado__CCM_Licenses_Enabled', Enabled__c = ccmLicensesInteger > 0, Quantity__c = ccmLicensesInteger));
        features.add(new Feature__c(Name = 'copado__CST_Licenses_Enabled', Enabled__c = cstLicensesInteger > 0, Quantity__c = cstLicensesInteger));
        features.add(new Feature__c(Name = 'copado__CCH_Licenses_Enabled', Enabled__c = cchLicensesInteger > 0, Quantity__c = cchLicensesInteger));
        features.add(new Feature__c(Name = 'copado__CBM_Branches', Enabled__c = cbmLicensesInteger > 0, Quantity__c = cbmLicensesInteger));

        // for Vlocity, we need to detect if it is available and enabled, and then backend expects Quantity>0 if enabled.  **** Requested by Nahuel *****
        if (syncVlocity) {
            Feature__c vlocityFeature = Feature__c.getAll().get('Vlocity');
            if (vlocityFeature != null) {
                features.add(vlocityFeature);
            }
        }

        // for OnPremise, we need to detect if it is available and enabled, and then backend expects Quantity>0 if enabled.  **** Requested by Nahuel *****
        if (syncOnPremiseDeployer) {
            Feature__c onPremiseFeature = Feature__c.getAll().get('On_Premise_Deployer');
            if (onPremiseFeature != null) {
                features.add(
                    new Feature__c(
                        Name = 'On_Premise_Deployer',
                        Enabled__c = onPremiseFeature.Enabled__c,
                        Quantity__c = onPremiseFeature.Enabled__c ? 1 : 0
                    )
                );
            }
        }

        RefreshFeaturesWrapper refreshOrgsFeatures = new RefreshFeaturesWrapper(Settings__c.getOrgDefaults(), features);
        return DeployAPI.refreshOrgFeatures(JSON.serialize(refreshOrgsFeatures));
    }

    private class RefreshFeaturesWrapper {
        private String userName { get; set; }
        private String userEmail { get; set; }
        private String orgName { get; set; }
        private String copadoVersion { get; set; }
        private String key { get; set; }
        private List<Feature__c> features { get; set; }
        private RefreshFeaturesWrapper(Settings__c copadoSettings, List<Feature__c> featuresList) {
            this.userName = UserInfo.getName();
            this.userEmail = UserInfo.getUserEmail();
            this.copadoVersion = copadoSettings.Current_Copado_Version__c;
            this.key = copadoSettings.CryptoKEY__c;
            this.features = new List<Feature__c>(featuresList);
        }
    }
}