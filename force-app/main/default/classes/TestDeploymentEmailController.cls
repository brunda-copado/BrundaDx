/**
 * Note: Asserts need three argument for supported PMD way.
 */
@SuppressWarnings('PMD')
@isTest
private class TestDeploymentEmailController {
    @testSetup
    static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void testFullComponent() {
        Org__c testFromOrg = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
        insert testFromOrg;
        testFromOrg.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
        update testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        insert testDeployment;
        Step__c testStep = testMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Git MetaData');
        Step__c testStep2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Git MetaData');
        insert new List<Step__c>{ testStep, testStep2 };
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [
            SELECT Id
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :testDeployment.Id AND Step__r.Type__c = 'Git MetaData'
            WITH USER_MODE
        ];
        System.assertEquals(2, testJobs.size(), 'the deployment job query did not return any records.');

        Test.startTest();
        DeploymentEmailController.deployId = null;
        DeploymentEmailController.getPodUrl();
        DeploymentEmailController.getDeploymentSteps();
        DeploymentEmailController.getErrorMessages();
        System.assertEquals(Label.Deployment_Not_Found, DeploymentEmailController.statusMessage);

        DeploymentEmailController.deployId = testDeployment.Id;
        DeploymentEmailController.getDeploymentSteps();
        DeploymentEmailController.getErrorMessages();
        System.assertEquals(Label.NO_ERROR_ATTACHMENT_FOUND, DeploymentEmailController.statusMessage);

        String attBody = '[{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""}]';
        system.debug('@@@ jobs Id: ' + testJobs[0].Id + '.json');
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id + '.json', attBody);
        insert testAttachment;
        attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        testAttachment = createAttachment(testStep.Id, 'MetaData', attBody);
        insert testAttachment;
        attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        testAttachment = createAttachment(testStep2.Id, 'MetaData', attBody);
        insert testAttachment;
        DeploymentEmailController.getDeploymentSteps();
        DeploymentEmailController.getErrorMessages();
        System.assertEquals('', DeploymentEmailController.statusMessage);

        Test.stopTest();
    }

    static testMethod void maxSizeAttachmentError() {
        Org__c testFromOrg = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
        insert testFromOrg;
        testFromOrg.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
        update testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        insert testDeployment;
        Step__c testStep = testMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Git MetaData');
        insert testStep;
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [
            SELECT Id
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :testDeployment.Id AND Step__r.Type__c = 'Git MetaData'
            WITH USER_MODE
        ];
        system.assertEquals(1, testJobs.size(), 'the deployment job query did not return any records.');

        test.startTest();
        DeploymentEmailController.getPodUrl();
        DeploymentEmailController.deployId = testDeployment.Id;
        //Now create attachment against deployment.
        String attBody = '{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass agf__ADM_AcceptanceCriterionCloner] unexpected token: \u0027(\u0027","t":""},';
        for (Integer i = 0; i <= 11; i++) {
            attBody += attBody;
        }
        attBody = attBody.substring(0, attBody.length() - 1); //removes last comma.
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id + '.json', '[' + attBody + ']');
        insert testAttachment;
        List<Attachment> attr = [SELECT Id, BodyLength FROM Attachment WHERE Id = :testAttachment.Id WITH USER_MODE];
        system.assert(attr[0].BodyLength > BuildTaskEmailController.MAX_BODY_LENGTH);
        DeploymentEmailController.getErrorMessages();
        system.assertEquals(
            Label.MAX_FILE_SIZE_EXCEEDED,
            DeploymentEmailController.statusMessage
        );

        test.stopTest();
    }

    static testMethod void maxSizeAttachmentMeta() {
        Org__c testFromOrg = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
        insert testFromOrg;
        testFromOrg.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
        update testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            testFromOrg.Id,
            'Deploy now',
            'Scheduled'
        );
        insert testDeployment;
        Step__c testStep = testMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Git MetaData');
        insert testStep;
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [
            SELECT Id
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :testDeployment.Id AND Step__r.Type__c = 'Git MetaData'
        ];
        system.assertEquals(1, testJobs.size(), 'the deployment job query did not return any records.');

        test.startTest();
        DeploymentEmailController.getPodUrl();
        DeploymentEmailController.deployId = testDeployment.Id;
        //Now create attachment against deployment.
        String attBody = '{\"t\":\"ApexTrigger\",\"n\":\"AccountTrigger\",\"s\":true},';
        for (Integer i = 0; i <= 11; i++) {
            attBody += attBody;
        }
        attBody = attBody.substring(0, attBody.length() - 1); //removes last comma.
        Attachment testAttachment = createAttachment(testStep.Id, 'MetaData', '[' + attBody + ']');
        insert testAttachment;
        List<Attachment> attr = [SELECT Id, BodyLength FROM Attachment WHERE Id = :testAttachment.Id WITH USER_MODE];
        system.assert(attr[0].BodyLength > BuildTaskEmailController.MAX_BODY_LENGTH);
        DeploymentEmailController.getDeploymentSteps();
        system.assertNotEquals(
            Label.MAX_FILE_SIZE_EXCEEDED,
            DeploymentEmailController.statusMessage
        );

        test.stopTest();
    }

    private static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(parentId = parentId, name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }
}