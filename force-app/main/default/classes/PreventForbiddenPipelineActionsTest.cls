@isTest
public with sharing class PreventForbiddenPipelineActionsTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void submiUserStoriesAction() {
        System.runAs(getUser()) {
            // Setup

            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                new PipelineAction().pipeline(getPipeline()).action(ActionConstants.SUBMIT_USER_STORIES).template(getJobTemplate()).persist();
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');

            System.assertEquals(
                0,
                [SELECT COUNT() FROM Pipeline_Action__c WHERE Action__c = :ActionConstants.SUBMIT_USER_STORIES],
                'A Submit User Stories Pipeline Action record should not be inserted.'
            );
        }
    }

    @IsTest
    private static void submiUserStoriesActionUpdate() {
        System.runAs(getUser()) {
            // Setup
            new PipelineAction().pipeline(getPipeline()).action(ActionConstants.COMMIT_ACTION).template(getJobTemplate()).persist();

            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                update new Pipeline_Action__c(Id = getPipelineAction(), Action__c = ActionConstants.SUBMIT_USER_STORIES);
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');

            System.assertEquals(
                0,
                [SELECT COUNT() FROM Pipeline_Action__c WHERE Action__c = :ActionConstants.SUBMIT_USER_STORIES],
                'A Submit User Stories Pipeline Action record should not be inserted.'
            );
        }
    }

    private static void createData() {
        new Pipeline()
            .setPlatform('Other')
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
            );
        new JobTemplate().add(new JobStep()).persist();
    }

    private static Id getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id;
    }

    private static Id getPipelineAction() {
        return [SELECT Id FROM Pipeline_Action__c LIMIT 1].Id;
    }

    private static Id getJobTemplate() {
        return [SELECT Id FROM JobTemplate__c LIMIT 1].Id;
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}