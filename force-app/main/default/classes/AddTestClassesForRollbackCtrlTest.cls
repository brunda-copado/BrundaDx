@IsTest
private with sharing class AddTestClassesForRollbackCtrlTest {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    private static void addTestClassForRb() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            // Setup
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            Step__c step = TestDataFactory.createStep(deployment.Id, 'Rollback step', 'Rollback', 'Not Started', 1, null, '');
            insert step;

            Test.startTest();
            // Exercise
            ApexPages.StandardController sc = new ApexPages.StandardController(step);
            AddTestClassesForRollbackCtrl controller = new AddTestClassesForRollbackCtrl(sc);
            Test.stopTest();

            // Verify
            System.assertEquals(controller.step.Id, step.Id, 'Step Id is not matching');
            System.assertEquals(controller.destinationOrgId, destinationOrg.To_Org__c, 'Destination org Id is not matching');
        }
    }

    private static User getAdminUserWithLicense() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);
        return sysUser;
    }
}