@IsTest
private class ValidateChangesCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesReadOnly())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void getValidationSettingWithInvalidRecordId() {
        // Setup & Exercise
        ValidateChangesCtrl.ValidationSetting result = ValidateChangesCtrl.getValidationSetting(UserInfo.getUserId());

        // Verify
        System.assertEquals(false, result.validationEnabled, 'Validation is not enabled.');
        System.assertEquals(Label.ValidateChangeError, result.title, 'Something went wrong while validating Changes.');
        System.assertEquals(Label.InvalidValidationContextId, result.message, 'Invalid context Id.');
    }

    @IsTest
    private static void getValidationSettingForPromotionWithoutPlatform() {
        System.runAs(getRunAsUser()) {
            // Setup
            SObject promotion = new Promotion(new Release(), new Credential(), new Credential()).persist();

            // Exercise
            ValidateChangesCtrl.ValidationSetting result = ValidateChangesCtrl.getValidationSetting(promotion.Id);

            // Verify
            System.assertEquals(false, result.validationEnabled, 'Validation is not enabled.');
        }
    }

    @IsTest
    private static void getValidationSettingForPromotionWithoutSetting() {
        System.runAs(getRunAsUser()) {
            // Setup
            SObject promotion = getPromotion();

            // Exercise
            ValidateChangesCtrl.ValidationSetting result = ValidateChangesCtrl.getValidationSetting(promotion.Id);

            // Verify
            System.assertEquals(false, result.validationEnabled, 'Validation is not enabled.');
        }
    }

    @IsTest
    private static void getValidationSettingForUserStoryWithoutPlatform() {
        System.runAs(getRunAsUser()) {
            // Setup
            SObject userStory = new UserStory().persist();

            // Exercise
            ValidateChangesCtrl.ValidationSetting result = ValidateChangesCtrl.getValidationSetting(userStory.Id);

            // Verify
            System.assertEquals(false, result.validationEnabled, 'Validation is not enabled.');
        }
    }

    @IsTest
    private static void getValidationSettingForUserStoryWithoutSetting() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStory();

            // Exercise
            ValidateChangesCtrl.ValidationSetting result = ValidateChangesCtrl.getValidationSetting(userStory.Id);

            // Verify
            System.assertEquals(false, result.validationEnabled, 'Validation is not enabled.');
        }
    }

    @IsTest
    private static void validateChangesForUserStory() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStory();
            createDeploymentSteps(userStory.Id);

            // Exercise
            Test.startTest();
            Id result = ValidateChangesCtrl.validateChanges(userStory.Id, getDeploymentSteps());
            Test.stopTest();

            // Verify
            System.assertEquals(
                'Promotion__c',
                result.getSobjectType().getDescribe(SObjectDescribeOptions.DEFAULT).getLocalName(),
                'Result must be promotion record id.'
            );
        }
    }

    @IsTest
    private static void validateChangesForUserStoryInProduction() {
        System.runAs(getRunAsUser()) {
            // Setup
            Release__c release = new Release__c(Project__c = [SELECT Id FROM Project__c LIMIT 1].Id);
            insert release;

            SObject userStory = new UserStory()
                .credentialId([SELECT Id FROM Org__c WHERE Environment__r.Name = 'int' LIMIT 1].Id)
                .releaseId(release.Id)
                .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
                .persist();

            // Exercise
            ValidateChangesCtrl.ValidationSetting result = ValidateChangesCtrl.getValidationSetting(userStory.Id);

            // Verify
            System.assertEquals(false, result.validationEnabled, 'Validation is not enabled.');
        }
    }

    @IsTest
    private static void validateChangesForPromotion() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = getPromotion();

            // Exercise
            Test.startTest();
            Id result = ValidateChangesCtrl.validateChanges(promotion.Id, getDeploymentSteps());
            Test.stopTest();

            // Verify
            System.assertEquals(
                'Promotion__c',
                result.getSobjectType().getDescribe(SObjectDescribeOptions.DEFAULT).getLocalName(),
                'Result must be promotion record id.'
            );
        }
    }

    @IsTest
    private static void validateChangesForInValidRecordId() {
        // Setup
        Exception expectedException = null;

        // Exercise
        try {
            ValidateChangesCtrl.validateChanges(UserInfo.getUserId(), new List<Id>{});
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        System.assertNotEquals(null, expectedException, 'Exception must occur.');
    }

    // HELPER

    private static void createData() {
        new JobTemplate()
            .name('JOB_TEMPLATE_PROMOTION')
            .mockAutomation('Promotion')
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
            .persist();

        Credential source = new Credential();

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().name('int').platform('Other').add(new Credential())
                    )
                    .branch('dev1')
            )
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
                    .branch('dev2')
            )
            .add(new Project().add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();
    }

    private static void createDeploymentSteps(Id userStoryId) {
        new JobStep().executionSequence(PromotionConstants.BEFORE_VALUE).userStory(userStoryId);
        new JobStep().executionSequence(PromotionConstants.AFTER_VALUE).userStory(userStoryId).persist();
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
    }

    private static Promotion__c getPromotion() {
        User_Story__c userStory = getUserStory();
        createDeploymentSteps(userStory.Id);

        Promotion__c promotion = (Promotion__c) new Promotion()
            .projectId(userStory.Project__c)
            .sourceEnvId(userStory.Environment__c)
            .status(PromotionConstants.STATUS_DRAFT)
            .persist();

        new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id).persist();
        return promotion;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static List<Id> getDeploymentSteps() {
        List<Id> result = new List<Id>();
        for (JobStep__c jobStep : [SELECT Id FROM JobStep__c]) {
            result.add(jobStep.Id);
        }
        return result;
    }
}