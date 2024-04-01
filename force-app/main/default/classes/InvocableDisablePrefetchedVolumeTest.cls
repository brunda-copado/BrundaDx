@IsTest
private class InvocableDisablePrefetchedVolumeTest {

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
    private static void executeWithPrefetchEnabled() {

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

            new PipelineAction()
                    .pipeline(pipeline.Id)
                    .action('Commit')
                    .template(new JobTemplate()
                                    .name('Commit')
                                    .add(new JobStep().name('Use Prefetched Volume'))
                                    .add(new JobStep().name('Normal step')));
            new PipelineAction()
                    .pipeline(pipeline.Id)
                    .action('Promotion')
                    .template(new JobTemplate()
                                    .name('Promotion')
                                    .add(new JobStep().name('Use Prefetched Volume'))
                                    .add(new JobStep().name('Normal step')));
            new PipelineAction()
                    .pipeline(pipeline.Id)
                    .action('PromotionDeployment')
                    .template(new JobTemplate()
                                    .name('PromotionDeployment')
                                    .add(new JobStep().name('Use Prefetched Volume'))
                                    .add(new JobStep().name('Normal step')));

            new PipelineAction()
                    .pipeline(pipeline.Id)
                    .action('CreatePackageVersion')
                    .template(new JobTemplate()
                                    .name('CreatePackageVersion')
                                    .add(new JobStep().name('Use Prefetched Volume'))
                                    .add(new JobStep().name('Normal step')))
                    .persist();

            // Exercise
            InvocableDisablePrefetchedVolume.InvocableVariables input = new InvocableDisablePrefetchedVolume.InvocableVariables();
            input.pipelineId = pipeline.Id;
            input.repoId = repository.Id;
            InvocableDisablePrefetchedVolume.execute(new List<InvocableDisablePrefetchedVolume.InvocableVariables> { input });


            // Verify
            Assert.areEqual(5, [SELECT count() FROM JobStep__c]);
            Assert.areEqual(0, [SELECT count() FROM System_Property__c]);
            Assert.areEqual(0, [SELECT count() FROM PreFetchedVolumes__c]);
        }
    }


    // HELPER

    private static User getUser() {
        return [SELECT Id, Email, Name, LastName, Username FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}