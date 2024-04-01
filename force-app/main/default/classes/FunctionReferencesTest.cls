@IsTest
private class FunctionReferencesTest {

    @TestSetup
    private static void setup() {
        setupUser();
    }

    @IsTest
    private static void getReferences() {
        System.runAs( standardUser() ) {
    
            // Setup

            Function__c f = (Function__c) new Function().persist();

            JobTemplate__c job = (JobTemplate__c) new JobTemplate()
                .name('Job1')
                .add(new JobStep()
                            .name('S1')
                            .type('Function')
                            .configJson('{"functionName":"' + f.API_Name__c + '"}')
                    )
                .add( new JobStep().name('S2') )
                .persist();

            // Exercise

            List<FunctionReferences.Step> result = FunctionReferences.getReferences(f.Id);

            // Verify

            System.assertEquals(1, result.size(), 'Incorrect job step count.');
            System.assertEquals('S1', result[0].name, 'Incorrect step name.');
            System.assertEquals(job.Id, result[0].parentId, 'Incorrect parent Id.');
            System.assertEquals(job.Name, result[0].parentName, 'Incorrect parent name.');
            System.assertEquals('Job Step', result[0].type, 'Incorrect step type.');
        }
    }


    @IsTest
    private static void invalidStepConfig() {
        System.runAs( standardUser() ) {
    
            // Setup

            Function__c f = (Function__c) new Function().persist();

            new JobTemplate()
                .name('Job1')
                .add(new JobStep()
                    .name('Null JSON S1')
                    .type('Function')
                    .configJson(null)
                )
                .add(new JobStep()
                    .name('Invalid JSON S2')
                    .type('Function')
                    .configJson('{{{{"functionName":"' + f.API_Name__c + '"}' )
                )
                .add(new JobStep()
                    .name('S3')
                    .type('Function')
                    .configJson('{"functionName":"' + f.API_Name__c + '"}' )
                )
                .persist();

            // Exercise

            List<FunctionReferences.Step> result = FunctionReferences.getReferences(f.Id);

            // Verify

            System.assertEquals(1, result.size(), 'Incorrect job step count.');
            System.assertEquals('S3', result[0].name, 'Incorrect step name.');
        }
    }


    @IsTest
    private static void exception() {
        System.runAs( standardUser() ) {
    
            // Setup

            Exception expectedEx = null;

            // Exercise
    
            try {
                FunctionReferences.getReferences(null);
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Invalid_Function_Id, expectedEx.getMessage(), 'Function Id should be invalid.');
        }
    }

    // HELPER

    private static void setupUser() {
        TestUtilities.getAllMultilicense();

        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
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