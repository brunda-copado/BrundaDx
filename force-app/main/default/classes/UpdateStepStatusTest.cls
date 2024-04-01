@IsTest
private class UpdateStepStatusTest {
    @TestSetup
    private static void setupData() {
        List<User> users = TestDataFactory.createUsers();
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Job_Engine')]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = users[0].Id, PermissionSetId = ps.Id));
        }
        insert assignments;
    }

    @IsTest
    private static void executeManualStatusUpdateComplete() {
        // Setup

        Helper helper = new Helper()
            .createExecution('Failed')
            .addStep('step1', 'Flow', 1, '{"flowName" : "MockedFlow"}')
            .addResultFor('step1', 'MockedFlow', 'Success');

        // Exercise + Verify

        System.runAs(user()) {
            Test.startTest();
            UpdateStepStatus.handleUpdate(helper.steps[0].Id, 'Complete', 'test complete');

            List<Event__e> eventList = UpdateStepStatus.eventList;
            System.assertEquals(1, eventList.size(), 'Platform Event should be created.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void executeManualStatusUpdateInComplete() {
        // Setup

        Helper helper = new Helper()
            .createExecution('Failed')
            .addStep('step1', 'Flow', 1, '{"flowName" : "MockedFlow"}')
            .addResultFor('step1', 'MockedFlow', 'Success');

        // Exercise + Verify

        System.runAs(user()) {
            Test.startTest();
            UpdateStepStatus.handleUpdate(helper.steps[0].Id, 'Incomplete', 'test incomplete');

            List<Event__e> eventList = UpdateStepStatus.eventList;
            System.assertEquals(1, eventList.size(), 'Platform Event should be created.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void executeManualStatusUpdatePending() {
        // Setup

        Helper helper = new Helper()
            .createExecution('Failed')
            .addStep('step1', 'Flow', 1, '{"flowName" : "MockedFlow"}')
            .addResultFor('step1', 'MockedFlow', 'Success');

        // Exercise

        System.runAs(user()) {
            Test.startTest();
            UpdateStepStatus.handleUpdate(helper.steps[0].Id, 'Pending', 'test Pending');

            List<Event__e> eventList = UpdateStepStatus.eventList;
            System.assertEquals(0, eventList.size(), 'Platform Event should be created.');
            Test.stopTest();
        }

        // Verify

        JobStep__c step1 = [SELECT Result__r.Result_Data__c, Status__c FROM JobStep__c WHERE Name = 'step1'];
        System.assertEquals('In Progress', step1.Status__c);
        System.assertEquals('test Pending', step1.Result__r.Result_Data__c);
    }

    // HELPER

    private class Helper {
        private JobTemplate__c template;
        private JobExecution__c execution;
        private List<JobStep__c> steps = new List<JobStep__c>();

        private Helper createExecution(String status) {
            template = new JobTemplate__c(Name = 'Sample', Version__c = 1);
            insert template;
            execution = new JobExecution__c(Template__c = template.Id, Status__c = status);
            insert execution;

            return this;
        }

        @SuppressWarnings('PMD.ExcessiveParameterList')
        private Helper addStep(String name, String type, Integer order, String configJson) {
            JobStep__c step = new JobStep__c();
            step.Name = name;
            step.Type__c = 'Manual';
            step.Order__c = 1;
            step.ConfigJson__c = configJson;
            step.JobExecution__c = execution.Id;
            insert step;

            steps.add(step);

            return this;
        }

        private Helper addResultFor(String stepName, String type, String status) {
            JobStep__c step = findByName(stepName);
            Result__c result = new Result__c(JobStep__c = step.Id, Job_Type__c = type, Status__c = status);
            insert result;

            step.Result__c = result.Id;
            update step;

            return this;
        }

        private JobStep__c findByName(String stepName) {
            JobStep__c result;

            for (JobStep__c step : steps) {
                if (step.Name == stepName) {
                    result = step;
                    break;
                }
            }

            return result;
        }
    }

    private static User user() {
        return [SELECT Id FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
    }
}