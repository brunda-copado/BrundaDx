@IsTest
private class CloneFunctionHandlerTest {

    @TestSetup
    private static void makeData() {
        setupUser();
    }

    @IsTest
    private static void functionClone() {
        System.runAs( standardUser() ) {
    
            // Setup

            Function__c func = (Function__c) new Function().persist();

            Function__c newFunc = func.clone();
            newFunc.Name = 'Function2';
            newFunc.API_Name__c = 'Function_2';
            newFunc.Description__c = 'New Description';

            // Exercise

            Id result = CloneFunctionHandler.cloneFunction(func.Id, newFunc);

            // Verify
            
            Function__c clonedFunc = [
                SELECT Name, API_Name__c, Type__c, Description__c
                FROM Function__c
                WHERE Name = 'Function2'
                LIMIT 1
            ];

            System.assertEquals(result, clonedFunc.Id, 'Incorrect Function.');
            System.assertEquals(newFunc.Name, clonedFunc.Name, 'Incorrect Name.');
            System.assertEquals('Custom', clonedFunc.Type__c, 'Incorrect Type.');
            System.assertEquals(newFunc.API_Name__c, clonedFunc.API_Name__c, 'Incorrect API Name.');
            System.assertEquals(newFunc.Description__c, clonedFunc.Description__c, 'Incorrect Description.');
        }
    }


    @IsTest
    private static void exception() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedException = null;

            // Exercise

            try {
                CloneFunctionHandler.cloneFunction(null, null);
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedException, 'The function is not created');
        }
    }

    // HELPER

    private static void setupUser() {
        TestUtilities.getAllMultilicense();

        User u = (User) new User_t()
            .assign( new PermissionSetAssignment_t().copadoUser() )
            .assign( new PermissionSetAssignment_t().functions() )
            .persist();

        System.runAs(u) {
            new CopadoLicense().user(u).enableAll().persist();
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