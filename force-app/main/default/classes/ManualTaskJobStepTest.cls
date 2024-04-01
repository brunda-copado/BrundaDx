@IsTest
private class ManualTaskJobStepTest {
    @TestSetup
    private static void setup() {
        setupUser();
    }

    @IsTest
    private static void execute() {
        System.runAs(standardUser()) {
            // Setup

            JobEngine.StepConfig stepConfig = new JobEngine.StepConfig();
            stepConfig.parameters = new List<CopadoFunctions.FunctionParameter>{
                new CopadoFunctions.FunctionParameter('assigneeId', UserInfo.getUserId()),
                new CopadoFunctions.FunctionParameter('assigneeName', UserInfo.getUserName())
            };

            JobStep s1 = new JobStep().type('Manual').configJson(JSON.serialize(stepConfig));
            JobExecution__c job = (JobExecution__c) new JobExecution().add(s1).persist();
            JobStep__c step = (JobStep__c) s1.record;

            // Exercise

            new ManualTaskJobStep(step, job).execute();

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
        }
    }

    @IsTest
    private static void invalidConfig() {
        System.runAs(standardUser()) {
            // Setup

            JobEngine.StepConfig stepConfig = new JobEngine.StepConfig();
            stepConfig.parameters = new List<CopadoFunctions.FunctionParameter>{
                new CopadoFunctions.FunctionParameter('assigneeId', null),
                new CopadoFunctions.FunctionParameter('assigneeName', null)
            };

            JobStep s1 = new JobStep().type('Manual').configJson(JSON.serialize(stepConfig));
            JobExecution__c job = (JobExecution__c) new JobExecution().add(s1).persist();
            JobStep__c step = (JobStep__c) s1.record;

            // Exercise

            new ManualTaskJobStep(step, job).execute();

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
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

    private static User standardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org' ORDER BY CreatedDate DESC LIMIT 1];
    }
}