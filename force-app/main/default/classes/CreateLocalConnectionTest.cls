@IsTest
private class CreateLocalConnectionTest {
    
    @TestSetup
    private static void setupData() {
        List<User> users = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = users[0].Id, PermissionSetId = ps.Id);
    }
    
    @IsTest
    private static void execute() {
        // Setup
        User copadoUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        
        System.runAs(copadoUser) {
            TestUtilities.assignLicense(String.valueOf(copadoUser.Username), true, true, true, true, true);
            Environment__c targetEnvironment = new Environment__c(Name = 'Target', Platform__c = 'Other');
            insert targetEnvironment;
            
            Git_Repository__c repository = new Git_Repository__c (Name = 'Repository');
            insert repository;
            
            Deployment_Flow__c pipeline = new Deployment_Flow__c(Name = 'Pipeline', Platform__c = 'Other', Git_Repository__c = repository.Id);
            insert pipeline;
            
            // Exercise
            Id connectionId = new CreateLocalConnection(pipeline, targetEnvironment.Id).execute();
            
            // Verify
            Deployment_Flow_Step__c connection = [SELECT Id, Deployment_Flow__c, Branch__c, Destination_Environment__c, Source_Environment__r.Platform__c FROM Deployment_Flow_Step__c WHERE Id = :connectionId];
            System.assertEquals(pipeline.Id, connection.Deployment_Flow__c);
            System.assertEquals(targetEnvironment.Id, connection.Destination_Environment__c);
            System.assertEquals('copado-local-dev-user-' + UserInfo.getUserId(), connection.Branch__c);
            System.assertEquals(pipeline.Platform__c, connection.Source_Environment__r.Platform__c);
            System.assertEquals(1, [SELECT count() FROM Connection_Behavior__c WHERE Name = 'local']);
        }
    }
    
    @IsTest
    private static void executeWithExistingConnection() {
        // Setup
        Exception expectedException = null;
        User copadoUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1]; 
        
        System.runAs(copadoUser) {
            TestUtilities.assignLicense(String.valueOf(copadoUser.Username), true, true, true, true, true);
            Environment__c targetEnvironment = new Environment__c(Name = 'Target', Platform__c = 'Other');
            insert targetEnvironment;
            
            Git_Repository__c repository = new Git_Repository__c (Name = 'Repository');
            insert repository;
            
            Deployment_Flow__c pipeline = new Deployment_Flow__c(Name = 'Pipeline', Platform__c = 'Other', Git_Repository__c = repository.Id);
            insert pipeline;
            
            // Exercise
            try {
                new CreateLocalConnection(pipeline, targetEnvironment.Id).execute();
                new CreateLocalConnection(pipeline, targetEnvironment.Id).execute();
            }
            catch(CliException ex) {
                expectedException = ex;
            }
        }
        
        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.LocalEnvironmentExists));
    }
}