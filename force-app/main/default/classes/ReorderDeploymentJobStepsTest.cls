@IsTest
private class ReorderDeploymentJobStepsTest {

    @TestSetup
    private static void makeData() {
        setupUser();
    }

    @IsTest
    private static void withExistingSteps() {
        System.runAs( standardUser() ) {
            
            // Setup

            new UserStory()
                .add( new JobStep().executionSequence('before').order(1) )
                .add( new JobStep().executionSequence('before').order(2) )
                .add( new JobStep().executionSequence('after').order(1) )
                .persist();

            // Exercise

            JobStep__c afterStep = [SELECT Id FROM JobStep__c WHERE ExecutionSequence__c = 'after'];
            afterStep.ExecutionSequence__c = 'before';
            update afterStep;

            // Verify

            JobStep__c s = [SELECT ExecutionSequence__c, Order__c FROM JobStep__c WHERE Id = :afterStep.Id];
            System.assertEquals('before', s.ExecutionSequence__c);
            System.assertEquals(3, s.Order__c);
        }
    }


    @IsTest
    private static void withoutSteps() {
        System.runAs( standardUser() ) {
            
            // Setup

            new UserStory().add( new JobStep().executionSequence('after').order(1) )
                .persist();

            // Exercise

            JobStep__c afterStep = [SELECT Id FROM JobStep__c WHERE ExecutionSequence__c = 'after'];
            afterStep.ExecutionSequence__c = 'before';
            update afterStep;

            // Verify

            JobStep__c s = [SELECT ExecutionSequence__c, Order__c FROM JobStep__c WHERE Id = :afterStep.Id];
            System.assertEquals('before', s.ExecutionSequence__c);
            System.assertEquals(1, s.Order__c);
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
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }
}