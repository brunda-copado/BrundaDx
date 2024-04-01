@IsTest
private class SetJobStepApiNameTest {
    @TestSetup
    private static void makeData() {
        setupUser();
    }

    @IsTest
    private static void executeWithParentTemplate() {
        System.runAs(runAsUser()) {
            // Setup

            JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1);
            insert template;

            // Exercise

            insert new JobStep__c(Name = 'step1', JobTemplate__c = template.Id, Type__c = 'Manual', Order__c = 1);

            // Verify

            JobStep__c s = [SELECT ApiName__c, Name, Order__c, JobTemplate__r.ApiName__c FROM JobStep__c];
            System.assertEquals(s.JobTemplate__r.ApiName__c + '_step1_' + s.Order__c, s.ApiName__c, 'The step API name matches');
        }
    }

    @IsTest
    private static void executeWithParentTemplateAndNoName() {
        System.runAs(runAsUser()) {
            // Setup

            JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1);
            insert template;

            // Exercise

            insert new JobStep__c(JobTemplate__c = template.Id, Type__c = 'Manual', Order__c = 1);

            // Verify

            JobStep__c s = [SELECT ApiName__c, Name, Order__c, JobTemplate__r.ApiName__c FROM JobStep__c];
            System.assertEquals(s.JobTemplate__r.ApiName__c + '_null_' + s.Order__c, s.ApiName__c, 'The step API name matches');
        }
    }

    @IsTest
    private static void executeWithParentExecution() {
        System.runAs(runAsUser()) {
            // Setup

            JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1);
            insert template;

            JobExecution__c execution = new JobExecution__c(Template__c = template.Id);
            insert execution;

            // Exercise

            insert new JobStep__c(Name = 'Execute! ?step1', JobExecution__c = execution.Id, Type__c = 'Manual', Order__c = 1);

            // Verify

            JobStep__c s = [SELECT ApiName__c, Name, Order__c, JobExecution__r.Name FROM JobStep__c];
            System.assertEquals(s.JobExecution__r.Name + '_' + 'Execute_step1' + '_' + s.Order__c, s.ApiName__c, 'The step API name matches');
        }
    }

    @IsTest
    private static void withParentUserStory() {
        System.runAs(runAsUser()) {
            // Setup

            User_Story__c story = new User_Story__c();
            insert story;

            // Exercise

            insert new JobStep__c(Name = 'Flow for step1', UserStory__c = story.Id, Type__c = 'Manual', ExecutionSequence__c = 'after', Order__c = 1);

            // Verify

            JobStep__c s = [SELECT ApiName__c, Name, Order__c, UserStory__r.Name FROM JobStep__c];
            System.assertEquals(s.UserStory__r.Name + '_' + 'Flow_for_step1' + '_' + s.Order__c, s.ApiName__c, 'The step API name matches');
        }
    }

    @IsTest
    private static void noParent() {
        System.runAs(runAsUser()) {
            // Setup

            Exception expectedEx;

            // Exercise

            try {
                insert new JobStep__c(Name = 'step1', Type__c = 'Manual');
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'There is an exception');
        }
    }

    // HELPER

    private static void setupUser() {
        TestUtilities.getAllMultilicense();

        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    private static User runAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org' ORDER BY CreatedDate DESC LIMIT 1];
    }
}