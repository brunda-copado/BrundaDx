@IsTest
private with sharing class AppDetectorControllerTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().alias('TestUsr1').assign(new PermissionSetAssignment_t().copadoUser()).persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void updateDefaultAppForUserWithValidId() {
        System.runAs(getUser()) {
            Id copadoConsoleAppId = [SELECT DurableId FROM AppDefinition WHERE DeveloperName = 'Copado_Console' LIMIT 1].DurableId;

            // Setup & Exercise

            Exception expectedException = null;
            try {
                AppDetectorController.updateDefaultAppForUser(copadoConsoleAppId);
            } catch (Exception e) {
                expectedException = e;
            }

            // Verify

            UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];

            System.assertEquals(null, expectedException, 'Controller should not throw exception when updating default app for copado user!');
            System.assertEquals(copadoConsoleAppId, userAppInfo.AppDefinitionId, 'Controller did not update default app for copado user!');
        }
    }

    @IsTest
    private static void updateDefaultAppForUserWithInvalidAppId() {
        System.runAs(getUser()) {
            // Setup & Exercise

            Exception expectedException = null;
            try {
                AppDetectorController.updateDefaultAppForUser('XXXXXXXXXXXXXXXXXX');
            } catch (Exception e) {
                expectedException = e;
            }

            // Verify

            System.assertNotEquals(null, expectedException, 'Controller should not throw exception when updating default app for running user!');
        }
    }

    @IsTest
    private static void getCustomApplicationWithInvalidContextID() {
        System.runAs(getUser()) {
            // Setup & Exercise

            AppDetectorController.ApplicationContext applicationContext;
            Exception expectedException = null;
            try {
                applicationContext = AppDetectorController.getContext('XXXXXXXXXXXXXXXXXX', '');
            } catch (Exception e) {
                expectedException = e;
            }

            // Verify

            System.assertEquals(
                null,
                expectedException,
                'Controller should not throw exception when getting application context for invalid record!'
            );
            System.assertNotEquals(null, applicationContext, 'Controller should return empty ApplicationContext for invalid conext!');
        }
    }

    @IsTest
    private static void getApplicationContextWithValidContextId() {
        System.runAs(getUser()) {
            // Setup

            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(Key__c = 'CustomAppName', Value__c = 'Copado_Console')
            };

            // Exercise

            AppDetectorController.ApplicationContext context;
            Exception expectedException = null;
            Id packageId = [SELECT Id FROM Artifact__c WHERE Name = 'otherPackage' LIMIT 1].Id;

            try {
                context = AppDetectorController.getContext(packageId, '');
            } catch (Exception e) {
                expectedException = e;
            }

            // Verify

            System.assertEquals(null, expectedException, 'Controller should not throw exception when getting application context for valid record!');
            System.assertNotEquals(context.expectedAppId, context.currentAppId, 'Default user app is not same as expected app');
            System.assertEquals('Other', context.platform, 'Context platform is not Other');
        }

    }

    @IsTest
    private static void getApplicationContextWithValidContextIdAndPlatformField() {
        System.runAs(getUser()) {
            // Setup

            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(Key__c = 'CustomAppName', Value__c = 'Copado_Console')
            };

            // Exercise

            AppDetectorController.ApplicationContext context;
            Exception expectedException = null;
            Id packageId = [SELECT Id FROM Artifact__c WHERE Name = 'otherPackage' LIMIT 1].Id;

            try {
                context = AppDetectorController.getContext(packageId, 'Pipeline__r.Platform__c');
            } catch (Exception e) {
                expectedException = e;
            }

            // Verify

            System.assertEquals(null, expectedException, 'Controller should not throw exception when getting application context for valid record!');
            System.assertNotEquals(context.expectedAppId, context.currentAppId, 'Default user app is not same as expected app');
            System.assertEquals('Other', context.platform, 'Context platform is not Other');
        }
    }

    // Helper

    private static void createData() {
        new Pipeline().active(true).mainBranch('main').setPlatform('Other').persist();

        Id salesforcePackagerecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName()
            .get('Package_Artifact')
            .getRecordTypeId();
        Id gitRepositoryId = [SELECT Id FROM Git_Repository__c LIMIT 1].Id;
        Id pipelineId = [SELECT Id FROM Deployment_Flow__c WHERE Platform__c = 'Other' LIMIT 1].Id;
        insert new Artifact__c(
            Name = 'otherPackage',
            Pipeline__c = pipelineId,
            RecordTypeId = salesforcePackagerecordTypeId,
            Artifact_Repository__c = gitRepositoryId
        );

        Id copadoAppId = [SELECT DurableId FROM AppDefinition WHERE DeveloperName = 'Copado' LIMIT 1].DurableId;
        insert new UserAppInfo(AppDefinitionId = copadoAppId, UserId = UserInfo.getUserId(), FormFactor = 'Large');
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }
}