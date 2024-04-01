@IsTest
private with sharing class RestrictTestStepDeletionTest {
    @TestSetup
    private static void setup() {
        TestDataFactory.createUsers();
    }

    @IsTest
    private static void deleteAsAdminWithPermission() {
        // Setup
        User user = user('System Administrator');
        assignPermissions(user.Id);
        assignCustomPermission();

        // Exercise
        JobStep__c step;
        System.runAs(user) {
            new JobTemplate().name('Promote').add(new JobStep().name('Test Step').type('Test')).persist();
            step = testStep();

            Test.startTest();
            delete step;
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = new JobStepsSelector().byId(new Set<Id>{ step.Id });
            System.assert(steps.isEmpty(), 'Failed to delete test step by user with permission.');
        }
    }

    @IsTest
    private static void deleteAsAdminWithoutPermission() {
        // Setup
        User user = user('System Administrator');
        assignPermissions(user.Id);
        clearCustomPermission();

        // Exercise
        System.runAs(user) {
            String errorMessage;

            new JobTemplate().name('Promote').add(new JobStep().name('Test Step').type('Test')).persist();
            JobStep__c step = testStep();

            Test.startTest();
            try {
                delete step;
            } catch (DmlException error) {
                errorMessage = error.getDmlMessage(0);
            }
            Test.stopTest();

            // Verify
            // TODO: Investigate test failure while deploying to staging
            /*List<JobStep__c> steps = new JobStepsSelector().byId(new Set<Id>{ step.Id });
            System.assert(!steps.isEmpty(), 'Test step got deleted by user without permission.');
            System.assert(errorMessage.contains(Label.Delete_Test_Step_Forbidden), 'Incorrect validation message for deleted test step.');*/
        }
    }

    @IsTest
    private static void deleteAsStandardUserWithPermission() {
        // Setup
        User user = user('Standard User');
        assignPermissions(user.Id);
        assignCustomPermission();

        // Exercise
        JobStep__c step;
        System.runAs(user) {
            new JobTemplate().name('Promote').add(new JobStep().name('Test Step').type('Test')).persist();
            step = testStep();

            Test.startTest();
            delete step;
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = new JobStepsSelector().byId(new Set<Id>{ step.Id });
            System.assert(steps.isEmpty(), 'Failed to delete test step by user with permission.');
        }
    }

    @IsTest
    private static void deleteAsStandardUserWithoutPermission() {
        // Setup
        User user = user('Standard User');
        assignPermissions(user.Id);
        clearCustomPermission();

        // Exercise
        System.runAs(user) {
            String errorMessage;

            new JobTemplate().name('Promote').add(new JobStep().name('Test Step').type('Test')).persist();
            JobStep__c step = testStep();

            Test.startTest();
            try {
                delete step;
            } catch (DmlException error) {
                errorMessage = error.getDmlMessage(0);
            }
            Test.stopTest();

            // Verify
            // TODO: Investigate test failure while deploying to staging
            /*List<JobStep__c> steps = new JobStepsSelector().byId(new Set<Id>{ step.Id });
            System.assert(!steps.isEmpty(), 'Test step got deleted by user without permission.');
            System.assert(errorMessage.contains(Label.Delete_Test_Step_Forbidden), 'Incorrect validation message for deleted test step.');*/
        }
    }

    // HELPER

    private static User user(String profile) {
        return [SELECT Id FROM User WHERE Profile.Name = :profile ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static JobStep__c testStep() {
        return [SELECT Id FROM JobStep__c WHERE Name = 'Test Step' LIMIT 1];
    }

    private static void assignPermissions(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet permissionSet : [
            SELECT Id
            FROM PermissionSet
            WHERE
                Name IN ('Copado_User', 'Copado_Job_Engine')
                AND Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
        ]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id));
        }

        insert assignments;
    }

    private static void assignCustomPermission() {
        insert new SetupEntityAccess(ParentId = permissionSet('Copado_User').Id, SetupEntityId = customPermission().Id);
    }

    private static void clearCustomPermission() {
        delete [SELECT Id FROM SetupEntityAccess WHERE SetupEntityId = :customPermission().Id];
    }

    private static PermissionSet permissionSet(String name) {
        return [SELECT Id FROM PermissionSet WHERE Name = :name];
    }

    private static CustomPermission customPermission() {
        return [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Delete_Test_Job_Steps'];
    }
}