public with sharing class PackageHelper {
    public void verifyUser() {
        if (!Copado_License__c.getInstance().Enable_Copado__c) {
            throw new ApplicationException(Label.LicensesNotAssigned);
        }

        if (
            !Test.isRunningTest() && !FeatureManagement.checkPermission('Enable_Package_Creation')
        ) {
            throw new ApplicationException(Label.InsufficientPermissions);
        }
    }

    public void assertRequest(String jsonInformation) {
        try {
            JSON.deserializeUntyped(jsonInformation);
        } catch (JSONException ex) {
            throw new ApplicationException(Label.ERROR_PARSING_JSON + ' ' + ex.getMessage());
        }
    }

    public Artifact__c getPackage(String packageId) {
        List<Artifact__c> result = new ArtifactsSelector().byIds(new Set<Id>{ packageId });

        if (result.isEmpty()) {
            throw new ApplicationException(Label.InvalidPackageId);
        }

        if (String.isBlank(result[0].Pipeline__c)) {
            throw new ApplicationException(Label.NoPipelineLinkedToPackage);
        }

        if (String.isBlank(result[0].Pipeline__r.Git_Repository__c)) {
            throw new ApplicationException(Label.NoGitRepoLinked);
        }

        return result[0];
    }
}