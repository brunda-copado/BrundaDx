@isTest
private class ResultViewerCtrlTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        new User_t().standard().alias('noAccess');
        User stdUsr = (User) new User_t()
            .alias('stdUsr')
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(stdUsr) {
            new CopadoLicense().user(stdUsr).enableAll().persist();
            createTestData();
        }
    }

    @isTest
    private static void fetchFromRelatedJobStep() {
        System.runAs(standardUser()) {
            // Setup
            Id stepId = [SELECT Id FROM JobStep__c WHERE Name = 'Flow Step' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().step(stepId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals('c.showDetails', componentName, 'The component name returned matches the one on related Job Step');
        }
    }

    @isTest
    private static void fetchBlankFromRelatedJobStep() {
        System.runAs(standardUser()) {
            // Setup
            Id stepId = [SELECT Id FROM JobStep__c WHERE Name = 'Execute' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().step(stepId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals(null, componentName, 'The component name is null as the related job stop has no component defined');
        }
    }

    @isTest
    private static void fetchFromRelatedFunction() {
        System.runAs(standardUser()) {
            // Setup
            Id functionId = [SELECT Id FROM Function__c WHERE API_Name__c = 'MockedFunction' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().function(functionId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals('c.mockComponent', componentName, 'The component name returned matches the one on related function');
        }
    }

    @isTest
    private static void fetchBlankFromRelatedFunction() {
        System.runAs(standardUser()) {
            // Setup
            Id functionId = [SELECT Id FROM Function__c WHERE API_Name__c = 'SampleFunction' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().function(functionId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals(null, componentName, 'The component name is null as the related job stop has no component defined');
        }
    }

    @isTest
    private static void fetchComponentWhenStepAndFunctionExist() {
        System.runAs(standardUser()) {
            // Setup
            Id stepId = [SELECT Id FROM JobStep__c WHERE Name = 'Flow Step' LIMIT 1].Id;
            Id functionId = [SELECT Id FROM Function__c WHERE API_Name__c = 'MockedFunction' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().function(functionId).step(stepId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals('c.showDetails', componentName, 'The component name returned matches the one on related job step');
        }
    }

    @isTest
    private static void fetchWhenStepComponentIsBlank() {
        System.runAs(standardUser()) {
            // Setup
            Id stepId = [SELECT Id FROM JobStep__c WHERE Name = 'Execute' LIMIT 1].Id;
            Id functionId = [SELECT Id FROM Function__c WHERE API_Name__c = 'MockedFunction' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().function(functionId).step(stepId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals('c.mockComponent', componentName, 'The component name returned matches the one on related function');
        }
    }

    @isTest
    private static void fetchWhenFunctionComponentIsBlank() {
        System.runAs(standardUser()) {
            // Setup
            Id stepId = [SELECT Id FROM JobStep__c WHERE Name = 'Flow Step' LIMIT 1].Id;
            Id functionId = [SELECT Id FROM Function__c WHERE API_Name__c = 'SampleFunction' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().function(functionId).step(stepId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals('c.showDetails', componentName, 'The component name returned matches the one on related step');
        }
    }

    @isTest
    private static void fetchWhenBothComponentsAreBlank() {
        System.runAs(standardUser()) {
            // Setup
            Id stepId = [SELECT Id FROM JobStep__c WHERE Name = 'Execute' LIMIT 1].Id;
            Id functionId = [SELECT Id FROM Function__c WHERE API_Name__c = 'SampleFunction' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().function(functionId).step(stepId).persist();

            // Exercise
            String componentName = ResultViewerCtrl.fetchResultViewerComponent(result.Id);

            // Verify
            System.assertEquals(
                null,
                componentName,
                'The component name is null as neither the related job stop nor function has any component defined'
            );
        }
    }

    @isTest
    private static void fetchWhenRecordIdIsNull() {
        System.runAs(standardUser()) {
            // Setup
            Exception expectedException;

            // Exercise
            try {
                ResultViewerCtrl.fetchResultViewerComponent(null);
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Script-thrown exception', expectedException.getMessage(), 'Exception message should match');
        }
    }

    @isTest
    private static void fetchWithInsufficientAccess() {
        System.runAs(noAccessUser()) {
            // Setup
            Exception expectedException;
            Id functionId = [SELECT Id FROM Function__c WHERE API_Name__c = 'MockedFunction' LIMIT 1].Id;
            Result__c result = (Result__c) new Result().function(functionId).persist();

            // Exercise
            try {
                ResultViewerCtrl.fetchResultViewerComponent(result.Id);
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Script-thrown exception', expectedException.getMessage(), 'Exception message should match');
        }
    }

    // HELPER

    private static void createTestData() {
        new Function().apiName('MockedFunction').script('echo hi').resultViewerComponent('c.mockComponent');
        new Function().apiName('SampleFunction').script('echo hello world');

        new JobTemplate()
            .name('Sample')
            .add(new JobStep().name('Execute').type('Function'))
            .add(new JobStep().name('Flow Step').type('Flow').resultViewerComponent('c.showDetails'))
            .persist();
    }

    private static User standardUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'stdUsr' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User noAccessUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'noAccess' ORDER BY CreatedDate DESC LIMIT 1];
    }
}