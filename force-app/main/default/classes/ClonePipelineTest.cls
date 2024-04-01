@IsTest
private class ClonePipelineTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void getData() {
        System.runAs(user()) {
            // Setup
            Deployment_Flow__c pipeline = createPipeline('Salesforce');
            DataWrapper record;

            // Exercise
            Test.startTest();
            record = (DataWrapper) JSON.deserialize(ClonePipeline.getData(pipeline.Id), DataWrapper.class);
            Test.stopTest();

            // Verify
            System.assertEquals(pipeline.Id, record.pipeline.Id, 'Incorrect pipeline record returned.');
            System.assert(!record.connections.isEmpty(), 'No connections were returned for this pipeline.');
            System.assert(!record.environments.isEmpty(), 'No environments were returned for this pipeline.');
            System.assertEquals(null, record.properties, 'System properties should not be returned by this method.');
        }
    }

    @IsTest
    private static void getDataWithUseExistingEnvironments() {
        System.runAs(user()) {
            // Setup
            Deployment_Flow__c pipeline = createPipeline('Mulesoft');
            DataWrapper record;

            // Exercise
            Test.startTest();
            record = (DataWrapper) JSON.deserialize(ClonePipeline.getData(pipeline.Id), DataWrapper.class);
            Test.stopTest();

            // Verify
            System.assertEquals(pipeline.Id, record.pipeline.Id, 'Incorrect pipeline record returned.');
            System.assert(!record.connections.isEmpty(), 'No connections were returned for this pipeline.');
            System.assert(!record.environments.isEmpty(), 'No environments were returned for this pipeline.');
            System.assertEquals(null, record.properties, 'System properties should not be returned by this method.');
            System.assert(record.useExistingEnvironments, 'Non salesforce pipeline should use existing environemnts bydefault during clone');
            System.assert(record.copySystemPropertyValues, 'Copy system property values by defaults to true');
        }
    }

    @IsTest
    private static void saveSalesforcePipeline() {
        System.runAs(user()) {
            // Setup
            Deployment_Flow__c pipeline = createPipeline('Salesforce');
            DataWrapper record = (DataWrapper) JSON.deserialize(ClonePipeline.getData(pipeline.Id), DataWrapper.class);
            Id cloneId;

            // Exercise
            Test.startTest();
            cloneId = ClonePipeline.saveCopy(JSON.serialize(record));
            Test.stopTest();

            // Verify
            DataWrapper clone = (DataWrapper) JSON.deserialize(ClonePipeline.getData(cloneId), DataWrapper.class);
            System.assert(!clone.connections.isEmpty(), 'No connections were returned for this cloned pipeline.');
            System.assert(clone.environments.isEmpty(), 'Environments should not be cloned for a Salesforce pipeline.');
        }
    }

    @IsTest
    private static void saveMuleSoftSalesforcePipeline() {
        System.runAs(user()) {
            // Setup
            Deployment_Flow__c pipeline = createPipeline('Mulesoft');
            DataWrapper record = (DataWrapper) JSON.deserialize(ClonePipeline.getData(pipeline.Id), DataWrapper.class);
            record.useExistingEnvironments = false;
            Id cloneId;

            // Exercise
            Test.startTest();
            cloneId = ClonePipeline.saveCopy(JSON.serialize(record));
            Test.stopTest();

            // Verify
            DataWrapper clone = (DataWrapper) JSON.deserialize(ClonePipeline.getData(cloneId), DataWrapper.class);
            System.assert(!clone.connections.isEmpty(), 'No connections were returned for this cloned pipeline.');
            System.assert(!clone.environments.isEmpty(), 'Environments should cloned for a Mulesoft pipeline if useExistingEnvironments is false');
        }
    }

    @IsTest
    private static void saveNonSalesforcePipeline() {
        System.runAs(user()) {
            // Setup
            Deployment_Flow__c pipeline = createPipeline('Other');
            DataWrapper record = (DataWrapper) JSON.deserialize(ClonePipeline.getData(pipeline.Id), DataWrapper.class);
            Id cloneId;

            // Exercise
            Test.startTest();
            cloneId = ClonePipeline.saveCopy(JSON.serialize(record));
            Test.stopTest();

            // Verify
            DataWrapper clone = (DataWrapper) JSON.deserialize(ClonePipeline.getData(cloneId), DataWrapper.class);
            System.assert(!clone.connections.isEmpty(), 'No connections were returned for this cloned pipeline.');
            System.assert(!clone.environments.isEmpty(), 'No connections were returned for this cloned pipeline.');
        }
    }

    // Helper

    private static User user() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c createPipeline(String platform) {
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform(platform).add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform(platform).add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform(platform).add(new Credential());

        Pipeline newPipeline = new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform(platform)
            .add(new Connection(dev1, uat).branch('dev1'))
            .add(new Connection(uat, prod).branch('uat'));

        new SystemProperty().apiName('DBName').value('OracleDB').environment(dev1);
        new SystemProperty().apiName('DB-Provider').value('Oracle').environment(uat);
        new SystemProperty().apiName('Username').value('user@oracledb.com').pipeline(newPipeline);

        return (Deployment_Flow__c) newPipeline.persist();
    }

    private class DataWrapper {
        public Deployment_Flow__c pipeline;
        public List<Deployment_Flow_Step__c> connections;
        public List<Environment__c> environments;
        public List<System_Property__c> properties;
        public Boolean useExistingEnvironments;
        public Boolean copySystemPropertyValues;
    }
}