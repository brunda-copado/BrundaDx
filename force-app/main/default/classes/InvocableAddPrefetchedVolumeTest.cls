@IsTest
private class InvocableAddPrefetchedVolumeTest {

    @TestSetup
    private static void setupData() {
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


    @IsTest
    private static void executeWithPrefetchEnabledAndVolumeIdPreset() {

        // Setup
        System.runAs(getUser()) {
            Git_Repository__c repository = (Git_Repository__c) new Repository().persist();
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                                                                    .repository(repository.Id)
                                                                    .add( new SystemProperty()
                                                                                .apiName('PreFetchedRepository')
                                                                                .value('{ "ttl": 1440, "volumeSize": 5, "volumeAmount": 7 }'))
                                                                    .persist();
            PreFetchedVolumes__c preFetchedVolume = new PreFetchedVolumes__c(Name = repository.Id, Pipeline_Id__c = pipeline.Id, Volume_Id__c = '1234567890', Expiration_Date__c = Datetime.now().addMinutes(30));
            insert preFetchedVolume;

            new JobExecution()
                    .volumeOptions('[{"name": "transactionId", "value": "xxxxxxxx"}, {"name": "volumeId", "value": "xxxxxxxx"}]')
                    .add(new JobStep()
                                .repository(repository.Id)
                                .pipeline(pipeline.Id)
                                .result(new Result()))
                    .persist();

            Result__c result = [SELECT Id FROM Result__c];


            // Exercise
            Test.startTest();
            InvocableAddPrefetchedVolume.execute(new List<Id> { result.Id });
			Test.stopTest();

            // Verify
            Assert.areEqual(0, [SELECT count() FROM PreFetchedVolumes__c WHERE Volume_Id__c != null]);

            JobExecution__c job = [SELECT VolumeOptions__c FROM JobExecution__c];
            List<CopadoFunctions.FunctionParameter> parameters = (List<CopadoFunctions.FunctionParameter>) JSON.deserialize(job.VolumeOptions__c, List<CopadoFunctions.FunctionParameter>.class);

            Assert.areEqual(2, parameters.size());
            Assert.areEqual('xxxxxxxx', parameters[0].value);
            Assert.areEqual('1234567890', parameters[1].value);
        }
    }


    @IsTest
    private static void executeWithPrefetchEnabledAndVolumeIdUnset() {

        // Setup
        System.runAs(getUser()) {
            Git_Repository__c repository = (Git_Repository__c) new Repository().persist();
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                                                                    .repository(repository.Id)
                                                                    .add( new SystemProperty()
                                                                                .apiName('PreFetchedRepository')
                                                                                .value('{ "ttl": 1440, "volumeSize": 5, "volumeAmount": 7 }'))
                                                                    .persist();
            PreFetchedVolumes__c preFetchedVolume = new PreFetchedVolumes__c(Name = repository.Id, Pipeline_Id__c = pipeline.Id, Volume_Id__c = '1234567890', Expiration_Date__c = Datetime.now().addMinutes(30));
            insert preFetchedVolume;

            new JobExecution()
                    .volumeOptions('[{"name": "transactionId", "value": "xxxxxxxx"}]')
                    .add(new JobStep()
                                .repository(repository.Id)
                                .pipeline(pipeline.Id)
                                .result(new Result()))
                    .persist();

            Result__c result = [SELECT Id FROM Result__c];


            // Exercise
            Test.startTest();
            InvocableAddPrefetchedVolume.execute(new List<Id> { result.Id });
			Test.stopTest();

            // Verify
            Assert.areEqual(0, [SELECT count() FROM PreFetchedVolumes__c WHERE Volume_Id__c != null]);

            JobExecution__c job = [SELECT VolumeOptions__c FROM JobExecution__c];
            List<CopadoFunctions.FunctionParameter> parameters = (List<CopadoFunctions.FunctionParameter>) JSON.deserialize(job.VolumeOptions__c, List<CopadoFunctions.FunctionParameter>.class);

            Assert.areEqual(2, parameters.size());
            Assert.areEqual('xxxxxxxx', parameters[0].value);
            Assert.areEqual('1234567890', parameters[1].value);
        }
    }


    @IsTest
    private static void executeWithPrefetchDisabled() {

        // Setup
        System.runAs(getUser()) {
            Git_Repository__c repository = (Git_Repository__c) new Repository().persist();
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                                                                    .repository(repository.Id)
                                                                    .persist();
            PreFetchedVolumes__c preFetchedVolume = new PreFetchedVolumes__c(Name = repository.Id, Pipeline_Id__c = pipeline.Id, Volume_Id__c = '1234567890', Expiration_Date__c = Datetime.now().addMinutes(30));
            insert preFetchedVolume;

            new JobExecution()
                    .volumeOptions('[{"name": "transactionId", "value": "xxxxxxxx"}]')
                    .add(new JobStep()
                                .repository(repository.Id)
                                .pipeline(pipeline.Id)
                                .result(new Result()))
                    .persist();

            Result__c result = [SELECT Id FROM Result__c];


            // Exercise
            InvocableAddPrefetchedVolume.execute(new List<Id> { result.Id });


            // Verify
            Assert.areEqual(1, [SELECT count() FROM PreFetchedVolumes__c]);

            JobExecution__c job = [SELECT VolumeOptions__c FROM JobExecution__c];
            List<CopadoFunctions.FunctionParameter> parameters = (List<CopadoFunctions.FunctionParameter>) JSON.deserialize(job.VolumeOptions__c, List<CopadoFunctions.FunctionParameter>.class);

            Assert.areEqual(1, parameters.size());
            Assert.areEqual('xxxxxxxx', parameters[0].value);
        }
    }


    // HELPER

    private static User getUser() {
        return [SELECT Id, Email, Name, LastName, Username FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}