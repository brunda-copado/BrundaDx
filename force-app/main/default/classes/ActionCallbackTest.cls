@IsTest
private with sharing class ActionCallbackTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void apexCallback() {
        System.runAs(getRunAsUser()) {
            // Setup
            JobExecution__c job = (JobExecution__c) new JobExecution().status('Successful').persist();

            // Exercise
            Test.startTest();
            new ActionCallback(Settings.ns.replace('__', '.') + 'ActionCallbackMock', job, 'Successful').run();
            Test.stopTest();

            // Verify
            Result__c mockResult = [SELECT Result_Data__c FROM Result__c WHERE ParentId__c = :job.Id LIMIT 1];
            System.assertEquals('Action Callback executed', mockResult.Result_Data__c, 'Action callback should have been executed');
        }
    }

    @IsTest
    private static void flowCallback() {
        System.runAs(getRunAsUser()) {
            // Setup
            JobExecution__c job = (JobExecution__c) new JobExecution().status('Successful').persist();

            // Exercise
            Test.startTest();
            new ActionCallback(Settings.ns.replace('__', '.') + 'Job_Step_Flow', job, 'Successful').run();
            Test.stopTest();

            // Verify
            System.assert(true, 'Action callback should have been executed');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}