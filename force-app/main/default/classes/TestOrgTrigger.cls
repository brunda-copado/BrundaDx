@IsTest
private class TestOrgTrigger {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    @isTest
    private static void orgTriggerTest() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            BatchHelper.enforceScheduler();
            CronJobDetail cjd = [SELECT Id FROM CronJobDetail WHERE Name = 'Copado' AND JobType = '7' LIMIT 1];
            if (BatchHelper.isCopadoScheduled()) {
                System.abortJob([SELECT Id FROM CronTrigger WHERE CronJobDetailId = :cjd.Id LIMIT 1].Id);
            }
            Assert.areEqual(false, BatchHelper.isCopadoScheduled());

            Org__c testOrg = testMethodUtilities.createOrg('OrgName2', 'Sandbox', 'SFDC_OrgId2', 'SFDC_TOKEN', 'USERNAME', System.now());
            testOrg.Test_Frequency__c = 'Daily';
            insert testOrg;

            Assert.areEqual(true, BatchHelper.isCopadoScheduled());
        }
    }

    @isTest
    private static void environmentCreationTest() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(1, sysUser.Username);

            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(1);

            for (Environment__c environment : environments) {
                environment.Org_ID__c = UserInfo.getOrganizationId();
            }
            update environments;

            for (integer i = 0; i < credentials.size(); i++) {
                credentials[i].Username__c = UserInfo.getUserName();
                credentials[i].SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
                credentials[i].Oauth_Signature__c = credentials[i].Name;
                credentials[i].Validated_Date__c = System.now();
                credentials[i].Disable_Validation__c = true;
            }
            update credentials;

            List<Environment__c> expectedEnvironments = [
                SELECT Id, Name, Org_ID__c
                FROM Environment__c
                WHERE Org_ID__c = :UserInfo.getOrganizationId()
            ];
            Assert.areEqual(1, expectedEnvironments.size());
            List<Org__c> expectedCredentials = [SELECT Id, Environment__c, SFDC_Org_ID__c FROM Org__c];
            Assert.areEqual(expectedEnvironments[0].Id, expectedCredentials[0].Environment__c);
        }
    }

    @isTest
    private static void defaultCredVerificationTest() {
        String exceptionMessage;
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Data creation
            Environment__c devEnv = (Environment__c) new Environment().name('dev1').type('Production/Developer').platform('Salesforce').persist();
            new Credential().name('cred1').oAuthSignature('authentication').environment(devEnv.Id).persist();
            new Credential().name('cred2').oAuthSignature('authentication').environment(devEnv.Id).persist();
            
            devEnv.Org_ID__c = UserInfo.getOrganizationId();
            update devEnv;

            List<Org__c> credentials = [SELECT Id, Username__c, SFDC_Org_ID__c, Validated_Date__c, Default_Credential__c FROM Org__c];
            for (integer i = 0; i < credentials.size(); i++) {
                credentials[i].Username__c = UserInfo.getUserName();
                credentials[i].SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
                credentials[i].Validated_Date__c = System.now();
                credentials[i].Default_Credential__c=true;
            }

            //Need to do this to catch exception as partial update was not throwing exception and when doing
            //non-partial update, exception was not letting update the first record
            try {
                update credentials[0];
                update credentials[1];
            } catch(Exception e) {
                exceptionMessage=e.getMessage();
            }

            List<Environment__c> expectedEnvironments = [SELECT Id, Name, Org_ID__c FROM Environment__c WHERE Org_ID__c = :UserInfo.getOrganizationId()];
            List<Org__c> expectedCredentials = [SELECT Id, Environment__c, Default_Credential__c, SFDC_Org_ID__c FROM Org__c];            
            Assert.areEqual(expectedEnvironments[0].Id, expectedCredentials[0].Environment__c);
            Assert.areEqual(true, expectedCredentials[0].Default_Credential__c);
            Assert.areNotEqual(null, exceptionMessage);
        }
    }
}