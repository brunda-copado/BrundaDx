@IsTest
private class GeneratePreFetchedVolumeTest {

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
    private static void execute() {

        // Setup
        System.runAs(getUser()) {
            Git_Repository__c repository = (Git_Repository__c) new Repository().persist();
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                                                                    .repository(repository.Id)
                                                                    .add( new SystemProperty()
                                                                                .apiName('PreFetchedRepository')
                                                                                .value('{ "ttl": 1440, "volumeSize": 5, "volumeAmount": 7 }'))
                                                                    .persist();


            // Exercise
            new GeneratePreFetchedVolume(repository.Id, pipeline.Id).execute();


            // Verify
            Assert.areEqual(7, [SELECT count() FROM PreFetchedVolumes__c]);
        }
    }


    @IsTest
    private static void executeCallbackWithVolumeId() {

        // Setup
        System.runAs(getUser()) {
            Git_Repository__c repository = (Git_Repository__c) new Repository().persist();
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                                                                    .repository(repository.Id)
                                                                    .add( new SystemProperty()
                                                                                .apiName('PreFetchedRepository')
                                                                                .value('{ "ttl": 1440, "volumeSize": 5, "volumeAmount": 7 }'))
                                                                    .persist();
            PreFetchedVolumes__c preFetchedVolume = new PreFetchedVolumes__c(Name = repository.Id, Pipeline_Id__c = pipeline.Id, Expiration_Date__c = Datetime.now().addMinutes(30));
            insert preFetchedVolume;

            Function__c function = (Function__c) new Function()
                                                        .add(new Result()
                                                                    .resultData('{"volumeId": "' +preFetchedVolume.Id + '", "settingId": "' +preFetchedVolume.Id + '"}'))
                                                        .persist();

            Result__c result = [SELECT Id, Result_Data__c FROM Result__c];

            // Exercise
            new GeneratePreFetchedVolume().execute(function, result, 'Success');


            // Verify
            PreFetchedVolumes__c volume = [SELECT Id, Volume_Id__c FROM PreFetchedVolumes__c];
            Assert.areEqual(preFetchedVolume.Id, volume.Volume_Id__c);
        }
    }


    @IsTest
    private static void executeCallbackWithoutVolumeId() {

        // Setup
        System.runAs(getUser()) {
            Git_Repository__c repository = (Git_Repository__c) new Repository().persist();
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                                                                    .repository(repository.Id)
                                                                    .add( new SystemProperty()
                                                                                .apiName('PreFetchedRepository')
                                                                                .value('{ "ttl": 1440, "volumeSize": 5, "volumeAmount": 7 }'))
                                                                    .persist();
            insert new PreFetchedVolumes__c(Name = repository.Id, Pipeline_Id__c = pipeline.Id, Expiration_Date__c = Datetime.now().addMinutes(30));

            Function__c function = (Function__c) new Function()
                                                        .add(new Result())
                                                        .persist();

            Result__c result = [SELECT Id, Result_Data__c FROM Result__c];

            // Exercise
            new GeneratePreFetchedVolume().execute(function, result, 'Success');


            // Verify
            PreFetchedVolumes__c volume = [SELECT Id, Volume_Id__c FROM PreFetchedVolumes__c];
            Assert.isNull(volume.Volume_Id__c);
        }
    }


    // HELPER

    private static User getUser() {
        return [SELECT Id, Email, Name, LastName, Username FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}