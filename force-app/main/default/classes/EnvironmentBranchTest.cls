@IsTest
private class EnvironmentBranchTest {

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 20);

        User user = (User) new User_t()
                            .assign(new PermissionSetAssignment_t().copadoUser())
                            .assign(new PermissionSetAssignment_t().functions())
                            .assign(new PermissionSetAssignment_t().jobEngine())
                            .assign(new PermissionSetAssignment_t().configureAutomations())
                            .assign(new PermissionSetAssignment_t().executeAutomations())
                            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }


    @IsTest
    private static void executeSourceEnvironmentWithSourceAsDev() {
        System.runAs(getUser()) {

            // SETUP
            Environment__c dev1 = [SELECT Id FROM Environment__c WHERE Name = 'dev1'];
            Environment__c uat = [SELECT Id FROM Environment__c WHERE Name = 'uat'];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            new JobExecution()
                    .source(dev1.Id)
                    .destination(uat.Id)
                    .add(new JobStep().pipeline(pipeline.Id))
                    .persist();

            JobStep__c step = [SELECT Id FROM JobStep__c LIMIT 1];

            // EXERCISE
            String branchName = new SourceEnvironmentBranch().execute(step.Id);

            // VERIFY
            System.assertEquals('dev1', branchName, 'dev1 branch name is different');
        }
    }


    @IsTest
    private static void executeSourceEnvironmentWithSourceAsProd() {
        System.runAs(getUser()) {

            // SETUP
            Environment__c prod = [SELECT Id FROM Environment__c WHERE Name = 'prod'];
            Environment__c uat = [SELECT Id FROM Environment__c WHERE Name = 'uat'];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            new JobExecution()
                    .source(prod.Id)
                    .destination(uat.Id)
                    .add(new JobStep().pipeline(pipeline.Id))
                    .persist();
            JobStep__c step = [SELECT Id FROM JobStep__c LIMIT 1];

            // EXERCISE
            String branchName = new SourceEnvironmentBranch().execute(step.Id);

            // VERIFY
            System.assertEquals('main', branchName, 'main branch name is different');
        }
    }


    @IsTest
    private static void executeDestinationEnvironmentWithDestinationAsUat() {
        System.runAs(getUser()) {

            // SETUP
            Environment__c dev1 = [SELECT Id FROM Environment__c WHERE Name = 'dev1'];
            Environment__c uat = [SELECT Id FROM Environment__c WHERE Name = 'uat'];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            new JobExecution()
                    .source(dev1.Id)
                    .destination(uat.Id)
                    .add(new JobStep().pipeline(pipeline.Id))
                    .persist();
            JobStep__c step = [SELECT Id FROM JobStep__c LIMIT 1];

            // EXERCISE
            String branchName = new DestinationEnvironmentBranch().execute(step.Id);

            // VERIFY
            System.assertEquals('uat', branchName, 'uat branch name is different');
        }
    }


    @IsTest
    private static void executeDestinationEnvironmentWithDestinationAsDev() {
        System.runAs(getUser()) {

            // SETUP
            Environment__c dev1 = [SELECT Id FROM Environment__c WHERE Name = 'dev1'];
            Environment__c uat = [SELECT Id FROM Environment__c WHERE Name = 'uat'];
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            new JobExecution()
                    .source(uat.Id)
                    .destination(dev1.Id)
                    .add(new JobStep().pipeline(pipeline.Id))
                    .persist();
            JobStep__c step = [SELECT Id FROM JobStep__c LIMIT 1];

            // EXERCISE
            String branchName = new DestinationEnvironmentBranch().execute(step.Id);


            // VERIFY
            System.assertEquals('dev1', branchName, 'dev1 branch name is different');
        }
    }


    // HELPER

    private static void createData() {
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, uat).branch('dev1'))
            .add(new Connection(dev2, uat).branch('dev2'))
            .add(new Connection(uat, prod).branch('uat'))
            .persist();
    }


    private static User getUser() {
        return [SELECT Id, Username FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}