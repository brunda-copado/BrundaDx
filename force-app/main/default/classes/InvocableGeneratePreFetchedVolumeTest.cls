@IsTest
private class InvocableGeneratePreFetchedVolumeTest {

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

        System.runAs(getUser()) {
            // Setup
            Git_Repository__c repository = (Git_Repository__c) new Repository().persist();
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                                                                    .repository(repository.Id)
                                                                    .persist();

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
                                    .add(new JobStep().name('Normal step')));
            new PipelineAction()
                    .pipeline(pipeline.Id)
                    .action('PromotionDeployment')
                    .template(new JobTemplate()
                                    .name('PromotionDeployment')
                                    .add(new JobStep().name('Normal step')));

            new PipelineAction()
                    .pipeline(pipeline.Id)
                    .action('CreatePackageVersion')
                    .template(new JobTemplate()
                                    .name('CreatePackageVersion')
                                    .add(new JobStep().name('Normal step')))
                    .persist();
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            FeatureManagement.setPackageIntegerValue('PreFetched_Volume_Limit', 20);


            // Exercise
            InvocableGeneratePreFetchedVolume.InvocableVariables input = new InvocableGeneratePreFetchedVolume.InvocableVariables();
            input.numberOfVolumes = 5;
            input.pipelineId = pipeline.Id;
            input.repoId = repository.Id;
            input.volumeConfig = '{ "ttl": 7200, "volumeSize": 5, "volumeAmount": 5 }';
            InvocableGeneratePreFetchedVolume.execute(new List<InvocableGeneratePreFetchedVolume.InvocableVariables> { input });

            // Verify
            Assert.areEqual(1, [SELECT count() FROM Function__c WHERE API_Name__c = 'create_prefetched_volume']);
            Assert.areEqual(1, [SELECT count() FROM System_Property__c WHERE API_Name__c = 'PreFetchedRepository' AND Pipeline__c = :pipeline.Id]);
            Assert.areEqual(5, [SELECT count() FROM PreFetchedVolumes__c]);
            Assert.areEqual(7, [SELECT count() FROM JobStep__c]);
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email, Name, LastName, Username FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static MC_Result__e functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        MC_Result__e result = new MC_Result__e();
        result.IsFinished__c = true;
        result.Result_Data__c = data;
        result.IsSuccess__c = isSuccess;
        result.Error_Message__c = errorMessage;

        return result;
    }
}