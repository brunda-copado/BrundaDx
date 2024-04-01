@isTest
private with sharing class OrderStepsControllerTest {
    static {
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(user) {
            assignPermissions(user.Id);
        }
    }

    @testSetup
    private static void setup() {
        insertData();
    }

    @isTest
    private static void getSteps() {
        // Exercise

        List<JobStep__c> steps;

        System.runAs(user()) {
            Test.startTest();
            steps = OrderStepsController.getSteps(jobTemplate().Id);
            Test.stopTest();
        }

        // Verify

        System.assertEquals('Function', steps[0].Type__c, 'Incorrect order assigned to function step.');
        System.assertEquals('Flow', steps[1].Type__c, 'Incorrect order assigned to flow step.');
        System.assertEquals('Manual', steps[2].Type__c, 'Incorrect order assigned to manual step.');
    }

    @isTest
    private static void saveSteps() {
        // Setup

        List<JobStep__c> steps = OrderStepsController.getSteps(jobTemplate().Id);
        steps[0].Order__c = 2; // function
        steps[1].Order__c = 3; // flow
        steps[2].Order__c = 1; // manual

        // Exercise

        System.runAs(user()) {
            Test.startTest();
            OrderStepsController.saveSteps(steps);
            Test.stopTest();
        }

        // Verify

        steps = OrderStepsController.getSteps(jobTemplate().Id);
        System.assertEquals('Manual', steps[0].Type__c, 'Incorrect order assigned to manual step.');
        System.assertEquals('Function', steps[1].Type__c, 'Incorrect order assigned to function step.');
        System.assertEquals('Flow', steps[2].Type__c, 'Incorrect order assigned to flow step.');
    }

    @isTest
    private static void saveStepsError() {
        // Setup

        List<JobStep__c> steps = OrderStepsController.getSteps(jobTemplate().Id);
        steps[0].Type__c = null;

        // Exercise

        Exception error;

        System.runAs(user()) {
            Test.startTest();
            try {
                OrderStepsController.saveSteps(steps);
            } catch (Exception ex) {
                error = ex;
            }
            Test.stopTest();
        }

        // Verify

        System.assert(error.getMessage().contains('Required fields are missing'), 'Type__c should be a required field for JobStep__c.');
    }

    // HELPER

    private static JobTemplate__c jobTemplate() {
        return [SELECT Id FROM JobTemplate__c WHERE ApiName__c = 'Copado_Promote_1' LIMIT 1];
    }

    private static JobStep__c functionStep(Id parentId) {
        return new JobStep__c(Name = 'Echo Promote', Type__c = 'Function', JobTemplate__c = parentId, Order__c = 1);
    }

    private static JobStep__c flowStep(Id parentId) {
        return new JobStep__c(Name = 'Get Data JSON Config', Type__c = 'Flow', JobTemplate__c = parentId, Order__c = 2);
    }

    private static JobStep__c manualStep(Id parentId) {
        return new JobStep__c(Name = 'Manual Approval', Type__c = 'Manual', JobTemplate__c = parentId, Order__c = 3);
    }

    private static User user() {
        return [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    }

    private static void assignPermissions(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet permissionSet : [
            SELECT Id
            FROM PermissionSet
            WHERE
                Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')
                AND Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
        ]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id));
        }

        insert assignments;
    }

    private static void insertData() {
        JobTemplate__c template = new JobTemplate__c(Name = 'Copado Promote', Version__c = 1, Type__c = 'Custom');
        insert template;

        insert new List<JobStep__c>{ functionStep(template.Id), flowStep(template.Id), manualStep(template.Id) };
    }
}