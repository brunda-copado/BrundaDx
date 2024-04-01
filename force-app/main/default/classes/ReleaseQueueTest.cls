@IsTest
private class ReleaseQueueTest {
    @IsTest
    private static void executeWithInProgressJob() {
        // Setup
        new JobExecution()
                .add(new JobStep().name('step1'))
                .add(new JobStep().name('step2'))
                .persist();

        List<JobStep__c> steps = [SELECT Id, JobExecution__r.Name FROM JobStep__c];

        Queue.AddRequest request1 = new Queue.AddRequest();
        request1.contextId = steps[0].Id;
        request1.contextName = steps[0].JobExecution__r.Name;
        request1.resource = UserInfo.getName();
        request1.callback = CopadoQueueableTest.class;
        Queue.add(request1);

        Queue.AddRequest request2 = new Queue.AddRequest();
        request2.contextId = steps[1].Id;
        request2.contextName = steps[1].JobExecution__r.Name;
        request2.resource = UserInfo.getName();
        request2.callback = CopadoQueueableTest.class;
        Queue.add(request2);

        // Exercise
        delete steps[0];

        // Verify
        Assert.areEqual(1, [SELECT count() FROM Queue__c]);
    }

    @IsTest
    private static void executeWithInProgressJobs() {
        // Setup

        new JobExecution()
                .add(new JobStep().name('step1').order(1))
                .add(new JobStep().name('step2').order(2))
                .add(new JobStep().name('step3').order(3))
                .add(new JobStep().name('step4').order(4))
                .persist();

        List<JobStep__c> steps = [SELECT Id, JobExecution__r.Name FROM JobStep__c ORDER BY Order__c ASC];

        Queue.AddRequest request1 = new Queue.AddRequest();
        request1.contextId = steps[0].Id;
        request1.contextName = steps[0].JobExecution__r.Name;
        request1.resource = UserInfo.getName() + 'Queue1';
        request1.callback = CopadoQueueableTest.class;
        Queue.add(request1);

        Queue.AddRequest request2 = new Queue.AddRequest();
        request2.contextId = steps[1].Id;
        request2.contextName = steps[1].JobExecution__r.Name;
        request2.resource = UserInfo.getName() + 'Queue1';
        request2.callback = CopadoQueueableTest.class;
        Queue.add(request2);

        Queue.AddRequest request3 = new Queue.AddRequest();
        request3.contextId = steps[2].Id;
        request3.contextName = steps[2].JobExecution__r.Name;
        request3.resource = UserInfo.getName() + 'Queue2';
        request3.callback = CopadoQueueableTest.class;
        Queue.add(request3);

        Queue.AddRequest request4 = new Queue.AddRequest();
        request4.contextId = steps[3].Id;
        request4.contextName = steps[3].JobExecution__r.Name;
        request4.resource = UserInfo.getName() + 'Queue2';
        request4.callback = CopadoQueueableTest.class;
        Queue.add(request4);

        // Exercise
        delete new List<JobStep__c> {steps[0], steps[2]};

        // Verify
        Assert.areEqual(2, [SELECT count() FROM Queue__c]);
    }
}