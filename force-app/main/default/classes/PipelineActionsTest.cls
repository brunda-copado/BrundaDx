@IsTest
private with sharing class PipelineActionsTest {
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
    private static void noPermissions() {
        // Setup
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();

        System.runAs(user) {
            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                new PipelineAction().pipeline(getPipeline()).action('Commit').template(getJobTemplate()).persist();
            } catch (Exception e) {
                validationError = e;
            }

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY,
                validationError.getDmlType(0),
                'Permission exception should be thrown.'
            );
            System.assertEquals(0, [SELECT COUNT() FROM Pipeline_Action__c], 'A Pipeline Action record should not be inserted.');
        }
    }

    @IsTest
    private static void defaultAction() {
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            new PipelineAction().pipeline(getPipeline()).action('Commit').template(getJobTemplate()).default().persist();
            Test.stopTest();

            // Verify
            System.assertEquals(1, [SELECT COUNT() FROM Pipeline_Action__c], 'A Pipeline Action record should be inserted.');
        }
    }

    @IsTest
    private static void invalidEnvironment() {
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                new PipelineAction()
                    .pipeline(getPipeline())
                    .action('Commit')
                    .template(getJobTemplate())
                    .environment(new Environment().platform('Other').add(new Credential()))
                    .persist();
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assertEquals(0, [SELECT COUNT() FROM Pipeline_Action__c], 'A Pipeline Action record should not be inserted.');
        }
    }

    @IsTest
    private static void duplicatedAction() {
        System.runAs(getUser()) {
            // Setup
            new PipelineAction().pipeline(getPipeline()).action('Commit').template(getJobTemplate()).persist();

            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                new PipelineAction().pipeline(getPipeline()).action('Commit').template(getJobTemplate()).persist();
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assertEquals(1, [SELECT COUNT() FROM Pipeline_Action__c], 'A Pipeline Action record should not be inserted.');
        }
    }

    @IsTest
    private static void setOverride() {
        System.runAs(getUser()) {
            // Setup
            Pipeline_Action__c defaultAction = (Pipeline_Action__c) new PipelineAction()
                .pipeline(getPipeline())
                .action('Commit')
                .template(getJobTemplate())
                .default()
                .persist();
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('job2').add(new JobStep()).persist();

            // Exercise
            Test.startTest();
            Pipeline_Action__c newAction = (Pipeline_Action__c) new PipelineAction()
                .pipeline(getPipeline())
                .action('Commit')
                .template(template.Id)
                .environment(getEnvironment())
                .persist();
            Test.stopTest();

            // Verify
            System.assertEquals(
                defaultAction.Id,
                [SELECT Overrides_Pipeline_Action__c FROM Pipeline_Action__c WHERE Id = :newAction.Id]
                .Overrides_Pipeline_Action__c,
                'The Overrides Pipeline Action field should be populated.'
            );
        }
    }

    @IsTest
    private static void modifyDefaultAction() {
        System.runAs(getUser()) {
            // Setup
            Pipeline_Action__c action = (Pipeline_Action__c) new PipelineAction()
                .pipeline(getPipeline())
                .action('Commit')
                .template(getJobTemplate())
                .default()
                .persist();
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('job2').add(new JobStep()).persist();

            // Exercise
            Test.startTest();
            action.Job_Template__c = template.Id;
            update action;

            // Verify
            System.assertEquals(
                template.Id,
                [SELECT Job_Template__c FROM Pipeline_Action__c WHERE Id = :action.Id]
                .Job_Template__c,
                'The Pipeline Action should be updated.'
            );
        }
    }

    @IsTest
    private static void modifyDefaultActionError() {
        System.runAs(getUser()) {
            // Setup
            String defaultAction = 'Commit';
            Pipeline_Action__c action = (Pipeline_Action__c) new PipelineAction()
                .pipeline(getPipeline())
                .action(defaultAction)
                .template(getJobTemplate())
                .default()
                .persist();

            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                action.Action__c = 'Promotion';
                update action;
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assertEquals(
                defaultAction,
                [SELECT Action__c FROM Pipeline_Action__c WHERE Id = :action.Id]
                .Action__c,
                'The Pipeline Action should not be updated.'
            );
        }
    }

    @IsTest
    private static void deleteDefaultActionError() {
        System.runAs(getUser()) {
            // Setup
            Pipeline_Action__c action = (Pipeline_Action__c) new PipelineAction()
                .pipeline(getPipeline())
                .action('Commit')
                .template(getJobTemplate())
                .default()
                .persist();

            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                delete action;
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assertEquals(1, [SELECT COUNT() FROM Pipeline_Action__c], 'A Pipeline Action record should not be deleted.');
        }
    }

    private static void createData() {
        new Pipeline()
            .setPlatform('Other')
            .add(new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential())));
        new JobTemplate().add(new JobStep()).persist();
    }

    private static Id getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id;
    }

    private static Id getJobTemplate() {
        return [SELECT Id FROM JobTemplate__c LIMIT 1].Id;
    }

    private static Id getEnvironment() {
        return [SELECT Id FROM Environment__c LIMIT 1].Id;
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}