@isTest
public with sharing class ValidateScaConfigurationTest {
    private static Id dev1CredentialId;
    private static Id stagingCredentialId;
    private static Id productionCredentialId;
    private static Id pipelineId;
    private static Id pipelineConnDev1StagingId;
    private static Id pipelineConnStagingProdId;
    private static Id testUsId;

    private static final Id codescanRecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByName()
        .get('CodeScan')
        .getRecordTypeId();

    @TestSetup
    private static void setupData() {
        setupUser();
    }

    @IsTest
    private static void forOrgCredential() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
            insert scas;

            Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
                Static_Code_Analysis_Settings__c = scas.Id,
                Rule_Name__c = 'ApexBadCrypto',
                Priority__c = '3',
                Rule_Reference__c = 'category/apex/security.xml/ApexBadCrypto'
            );
            insert scar;

            configureData('master', new List<String>{ 'dev1', 'staging' }, scas, false);

            // Exercise && Verify no exception
            new ValidateScaConfiguration().forCredential(dev1CredentialId);
        }
    }

    @IsTest
    private static void forOrgCredentialWithPMDAndWrongGit() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c(
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByName().get('PMD').getRecordTypeId()
            );
            insert scas;

            Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
                Static_Code_Analysis_Settings__c = scas.Id,
                Rule_Name__c = 'ApexBadCrypto',
                Priority__c = '3',
                Rule_Reference__c = 'category/apex/security.xml/ApexBadCrypto'
            );
            insert scar;

            configureData('', new List<String>{ '', '' }, scas, false);

            // Exercise && Verify no exception
            new ValidateScaConfiguration().forCredential(dev1CredentialId);
        }
    }

    @IsTest
    private static void forOrgCredentialFailsForCodescanWithWrongGitForDev1() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c(RecordTypeId = codescanRecordTypeId);
            insert scas;

            configureData('master', new List<String>{ '', 'staging' }, scas, false);

            // Exercise
            String exMessage = '';
            try {
                new ValidateScaConfiguration().forCredential(dev1CredentialId); //any id can be passed for the sake of testing.
            } catch (Exception e) {
                exMessage = e.getMessage();
            }

            // Verify
            System.assertEquals(
                String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE_CONNECTION, new List<String>{ pipelineConnDev1StagingId }),
                exMessage,
                'A exception should throw with the message: ' +
                String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE_CONNECTION, new List<String>{ pipelineConnDev1StagingId })
            );
        }
    }

    @IsTest
    private static void forOrgCredentialFailsForCodescanWithWrongGitForStaging() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c(RecordTypeId = codescanRecordTypeId);
            insert scas;

            configureData('master', new List<String>{ 'dev1', '' }, scas, false);

            // Exercise
            String exMessage = '';
            try {
                new ValidateScaConfiguration().forCredential(stagingCredentialId); //any id can be passed for the sake of testing.
            } catch (Exception e) {
                exMessage = e.getMessage();
            }

            // Verify
            System.assertEquals(
                String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE_CONNECTION, new List<String>{ pipelineConnStagingProdId }),
                exMessage,
                'A exception should throw with the message: ' +
                String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE_CONNECTION, new List<String>{ pipelineConnStagingProdId })
            );
        }
    }

    @IsTest
    private static void forOrgCredentialFailsForCodescanWithWrongGitForProduction() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c(RecordTypeId = codescanRecordTypeId);
            insert scas;

            configureData('', new List<String>{ 'dev1', 'staging' }, scas, false);

            // Exercise
            String exMessage = '';
            try {
                new ValidateScaConfiguration().forCredential(productionCredentialId); //any id can be passed for the sake of testing.
            } catch (Exception e) {
                exMessage = e.getMessage();
            }

            // Verify
            System.assertEquals(
                String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE, new List<String>{ pipelineId }),
                exMessage,
                'A exception should throw with the message: ' + String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE, new List<String>{ pipelineId })
            );
        }
    }

    @IsTest
    private static void forOrgCredentialFailsWithoutPMDRules() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
            insert scas;

            configureData('master', new List<String>{ 'dev1', 'staging' }, scas, false);

            // Exercise
            String exMessage = '';
            try {
                new ValidateScaConfiguration().forCredential(dev1CredentialId); //any id can be passed for the sake of testing.
            } catch (Exception e) {
                exMessage = e.getMessage();
            }

            // Verify
            System.assertEquals(Label.SCA_RULES_NOT_FOUND, exMessage, 'A exception should throw with the message: ' + Label.SCA_RULES_NOT_FOUND);
        }
    }

    @IsTest
    private static void forUserStory() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
            insert scas;

            Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c(
                Static_Code_Analysis_Settings__c = scas.Id,
                Rule_Name__c = 'ApexBadCrypto',
                Priority__c = '3',
                Rule_Reference__c = 'category/apex/security.xml/ApexBadCrypto'
            );
            insert scar;

            configureData('master', new List<String>{ 'dev1', 'staging' }, scas, true);

            // Exercise && Verify no exception
            new ValidateScaConfiguration().forUserStory(testUsId);
        }
    }

    @IsTest
    private static void forUserStoryFailsWithoutRules() {
        System.runAs(getTestUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
            insert scas;

            configureData('master', new List<String>{ 'dev1', 'staging' }, scas, true);

            // Exercise
            String exMessage = '';
            try {
                new ValidateScaConfiguration().forUserStory(testUsId);
            } catch (Exception e) {
                exMessage = e.getMessage();
            }

            // Verify
            System.assertEquals(Label.SCA_RULES_NOT_FOUND, exMessage, 'A exception should throw with the message: ' + Label.SCA_RULES_NOT_FOUND);
        }
    }

    private static void configureData(
        String pipelineBranch,
        String[] pipelineConnectionBranches,
        Static_Code_Analysis_Settings__c scas,
        Boolean withMetadataAttachments
    ) {
        Git_Repository__c repository = new Git_Repository__c(Name = 'test');
        insert repository;

        Deployment_Flow__c pipeline = new Deployment_Flow__c(
            Name = 'test',
            Active__c = true,
            Main_Branch__c = pipelineBranch,
            Git_Repository__c = repository.Id,
            Static_Code_Analysis_Settings__c = scas.Id
        );
        insert pipeline;

        pipelineId = pipeline.Id;

        List<Environment__c> environments = new List<Environment__c>();
        for (Integer i = 0; i < 3; i++) {
            Environment__c environment = new Environment__c(Name = 'Env' + i);
            environments.add(environment);
        }
        insert environments;

        List<Org__c> orgCredentials = new List<Org__c>();
        for (Integer i = 0; i < 3; i++) {
            Org__c credential = new Org__c(Name = 'Org' + i, Environment__c = environments[i].Id);
            orgCredentials.add(credential);
        }
        insert orgCredentials;

        dev1CredentialId = orgCredentials.get(0).Id;
        stagingCredentialId = orgCredentials.get(1).Id;
        productionCredentialId = orgCredentials.get(2).Id;

        Project__c project = new Project__c(Name = 'Test Project', Deployment_Flow__c = pipeline.Id);
        insert project;

        User_Story__c userStory = new User_Story__c(Project__c = project.Id, Org_Credential__c = orgCredentials[0].Id);
        insert userStory;

        testUsId = userStory.Id;

        if (withMetadataAttachments) {
            List<Attachment> attachments = new List<Attachment>();
            String attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
            attachments.add(createAttachment(userStory.Id, 'MetaData', attBody));

            insert attachments;
        }

        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = pipeline.Id,
                Branch__c = pipelineConnectionBranches[0],
                Source_Environment__c = environments[0].Id,
                Destination_Environment__c = environments[1].Id
            )
        );
        inserts.add(
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = pipeline.Id,
                Branch__c = pipelineConnectionBranches[1],
                Source_Environment__c = environments[1].Id,
                Destination_Environment__c = environments[2].Id
            )
        );
        insert inserts;

        pipelineConnDev1StagingId = inserts[0].Id;
        pipelineConnStagingProdId = inserts[1].Id;

        Settings__c settings = new Settings__c();
        settings.Server_URL__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
        settings.CryptoKEY__c = EncodingUtil.base64Encode(key);
        insert settings;

        DeployAPI con = new DeployAPI();
        String b = '{"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
    }

    private static Attachment createAttachment(String parentId, String name, String body) {
        Attachment a = new Attachment(ParentId = parentId, Name = name);
        a.Body = Blob.valueOf(body);
        return a;
    }

    private static void setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];

        System.runAs(adminUser) {
            TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);
        }
    }

    private static User getTestUser() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        return testUser;
    }
}