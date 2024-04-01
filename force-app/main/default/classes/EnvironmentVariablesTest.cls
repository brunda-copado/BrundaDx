@IsTest
private class EnvironmentVariablesTest {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    private static List<Environment__c> environments;
    private static List<Org__c> credentials;
    private static List<Environmental_Variable__c> environmentVariables;

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        //Environment creation
        environments = new List<Environment__c>();
        for (Integer i = 0; i < 3; i++) {
            Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
            environment.Platform__c = 'Other';
            environments.add(environment);
        }
        insert environments;

        //Environment Variable creation
        environmentVariables = new List<Environmental_Variable__c>();
        for (Integer i = 0; i < 100; i++) {
            String text = 'environmentVariables' + i;
            environmentVariables.add(TestDataFactory.createEnvironmentVariable(text, text, text, environments[0].Id));
        }
        insert environmentVariables;

        // Org Credential creation
        credentials = [
            SELECT Id, Name, Environment__c, Platform__c, Oauth_Signature__c, Validated_Date__c, Disable_Validation__c, SFDC_Org_ID__c
            FROM Org__c
            WHERE Platform__c = 'Other'
        ];
        for (Org__c org : credentials) {
            org.Username__c = UserInfo.getUserName();
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
            org.Oauth_Signature__c = org.Name;
            org.Validated_Date__c = System.now();
            org.Disable_Validation__c = true;
            break;
        }
        update credentials;
    }

    @IsTest
    static void execute() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            data();

            String result = '';

            Test.startTest();
            EnvironmentVariables cls = new EnvironmentVariables();
            result = cls.execute(environments[0].Id);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Environment Variables JSON is null');

            List<EnvironmentVariables.EnvironmentVariablesRecord> records = (List<EnvironmentVariables.EnvironmentVariablesRecord>) JSON.deserialize(
                result,
                List<EnvironmentVariables.EnvironmentVariablesRecord>.class
            );
            System.assertEquals(environmentVariables.size(), records.size(), 'Environment Variables list size is not equal');
        }
    }
}