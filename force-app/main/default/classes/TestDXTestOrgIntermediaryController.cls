@isTest
private class TestDXTestOrgIntermediaryController {
    @TestSetup
    static void setup() {
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        createTestData();
    }

    private static void createTestData() {
        List<Environment__c> environments = new List<Environment__c>();
        Environment__c devHubEnvironment = CMTestMethodUtilities.createEnvironment('DEV-HUB-13', '000000000000000001');
        environments.add(devHubEnvironment);
        Environment__c environment = CMTestMethodUtilities.createEnvironment('DEV-13', '000000000000000000');
        environments.add(environment);
        insert environments;

        Org__c devHubCredential = CMTestMethodUtilities.createOrg(
            'DEV-13',
            'Production',
            '000000000000000001',
            null,
            null,
            System.now(),
            devHubEnvironment.Id
        );
        devHubCredential.is_Developer_Hub_Org__c = true;
        insert devHubCredential;
        Org__c credential = CMTestMethodUtilities.createOrg('DEV-13', 'Scratch Org - Test Only', '000000000000000000', null, null, System.now(), environment.Id);
        credential.Developer_Hub_Org__c = devHubCredential.Id;
        insert credential;

        List<Attachment> attachments = new List<Attachment>();
        Attachment definitionFile = new Attachment();
        definitionFile.Name = DXLabel.DEFINITION_FILE;
        definitionFile.Body = Blob.valueOf(
            '{"adminEmail" : "rtoro@copa.do", "country" : "US","description" : "","edition" : "Developer","hasSampleData" : false,"language" : "en_US","orgName" : "SO-0019648","username" : "","features" : [ ],"settings" : { }}'
        );
        definitionFile.ParentId = credential.Id;
        attachments.add(definitionFile);
        Attachment projectFile = new Attachment();
        projectFile.Name = DXLabel.PROJECT_FILE;
        projectFile.Body = Blob.valueOf(
            '{"sourceApiVersion":"45.0","sfdcLoginUrl":"https://login.salesforce.com","packageDirectories":[{"path":"force-app","definitionFile":"config/project-scratch-def.json","default":true},{"path":"RT_19.11","definitionFile":"config/project-scratch-def.json","default":false}],"namespace":""}'
        );
        projectFile.ParentId = credential.Id;
        attachments.add(projectFile);
        insert attachments;

        User_Story__c userStory = CMTestMethodUtilities.createUserStory('Test DXTestOrgIntermediaryController');
        insert userStory;

        Test_Script__c script = CMTestMethodUtilities.createTestScript('Test DXTestOrgIntermediaryController from apex code');
        script.User_Story__c = userStory.Id;
        insert script;

        Test_Run__c testRun = CMTestMethodUtilities.createTestRun(script.Id);
        testRun.User_Story__c = userStory.Id;
        insert testRun;

        Test_Run__c testRunQueried = [
            SELECT Id, Name
            FROM Test_Run__c
            WHERE User_Story__r.User_Story_Title__c = 'Test DXTestOrgIntermediaryController'
            LIMIT 1
        ];

        credential.Name = testRunQueried.Name + ' Scratch Org';
        credential.Scratch_Org_Status__c = 'Active';
        update credential;
    }

    @isTest
    static void testRedirectPage() {
        Test_Run__c testRun = [
            SELECT Id, Name
            FROM Test_Run__c
            WHERE User_Story__r.User_Story_Title__c = 'Test DXTestOrgIntermediaryController'
            LIMIT 1
        ];
        ApexPages.StandardController controller = new ApexPages.StandardController(testRun);
        DXTestOrgIntermediaryController extension = new DXTestOrgIntermediaryController(controller);
        PageReference pageRef = extension.redirectPage();
        System.assertNotEquals(pageRef, null, 'Page reference is not generated');
    }

    @isTest
    static void testRedirectPageWithExpiredOrg() {
        List<Org__c> orgList = new List<Org__c>();
        Org__c org = [SELECT Id FROM Org__c WHERE Scratch_Org_Status__c = 'Active' ORDER BY CreatedDate DESC LIMIT 1];
        org.Scratch_Org_Status__c = 'Expired';
        update org;
        Test_Run__c testRun = [
            SELECT Id, Name
            FROM Test_Run__c
            WHERE User_Story__r.User_Story_Title__c = 'Test DXTestOrgIntermediaryController'
            LIMIT 1
        ];
        ApexPages.StandardController controller = new ApexPages.StandardController(testRun);
        DXTestOrgIntermediaryController extension = new DXTestOrgIntermediaryController(controller);
        PageReference pageRef = extension.redirectPage();
        System.assertEquals(pageRef, null, 'Page reference is generated');
    }
}