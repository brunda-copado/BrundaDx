@IsTest
private class QueueTest {
    @IsTest
    private static void addWithoutAnyParameter() {
        // Setup
        Exception expectedException = null;
        String expectedErrorMessage = String.format(Label.MissingParameterValue, new List<String> {'Context Id, Resource, Callback'});


        // Exercise
        try {
            Queue.add(null);
        } catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        Assert.isNotNull(expectedException, 'Invalid input to Queue.add should throw an exception');
        Assert.areEqual(expectedErrorMessage,  expectedException.getMessage(), 'Exception message should specify all missing parameters');
    }


    @IsTest
    private static void addWithoutCallbackParameter() {
        // Setup
        Exception expectedException = null;
        String expectedErrorMessage = String.format(Label.MissingParameterValue, new List<String> {'Callback'});

        Queue.AddRequest request = new Queue.AddRequest();
        request.contextId = UserInfo.getUserId();
        request.contextName = UserInfo.getUserId();
        request.resource = UserInfo.getName();


        // Exercise
        try {
            Queue.add(request);
        } catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        Assert.isNotNull(expectedException, 'Invalid input to Queue.add should throw an exception');
        Assert.areEqual(expectedErrorMessage,  expectedException.getMessage(), 'Exception message should specify all missing parameters');
    }


    @IsTest
    private static void addFirstJob() {
        // Setup
        Queue.AddRequest request = new Queue.AddRequest();
        request.contextId = UserInfo.getUserId();
        request.contextName = UserInfo.getUserId();
        request.resource = UserInfo.getName();
        request.callback = CopadoQueueableTest.class;


        // Exercise
        Queue.add(request);


        // Verify
        List<Queue__c> queue = [SELECT Id, ContextId__c, Status__c, Resource__c  FROM Queue__c];

        Assert.areEqual(1, queue.size(), 'Queue should have 1 record');
        Assert.areEqual(UserInfo.getUserId(),  queue[0].ContextId__c, 'Context Id in queue should match');
        Assert.areEqual(UserInfo.getName(),  queue[0].Resource__c, 'Resource name in queue should match');
        Assert.areEqual('In Progress',  queue[0].Status__c, 'Status of queue should be In Progress');
    }


    @IsTest
    private static void addSecondJobWithSameResource() {
        // Setup
        insert new Queue__c(Name = UserInfo.getUserId(), ContextId__c = UserInfo.getUserId(), Resource__c = UserInfo.getName(), Status__c = 'In Progress');

        Queue.AddRequest request = new Queue.AddRequest();
        request.contextId = UserInfo.getUserId();
        request.contextName = UserInfo.getUserId();
        request.resource = UserInfo.getName();
        request.callback = CopadoQueueableTest.class;

        // Exercise
        Queue.add(request);


        // Verify
        List<Queue__c> queue = [SELECT Id, ContextId__c, Status__c, Resource__c  FROM Queue__c ORDER BY CreatedDate ASC];

        Assert.areEqual(2, queue.size(), 'Queue should have 1 record');
        Assert.areEqual(UserInfo.getUserId(),  queue[1].ContextId__c, 'Context Id in queue should match');
        Assert.areEqual(UserInfo.getName(),  queue[1].Resource__c, 'Resource name in queue should match');
        Assert.areEqual('Queued',  queue[1].Status__c, 'Status of queue should be Queued');
    }


    @IsTest
    private static void blockAndAddSecondJobWithSameTransactionId() {
        // Setup
        insert new Queue__c(Name = UserInfo.getUserId(), ContextId__c = UserInfo.getUserId(), Resource__c = UserInfo.getName(), Transaction__c = 'T1', Status__c = 'In Progress');

        Queue.AddRequest request = new Queue.AddRequest();
        request.contextId = UserInfo.getOrganizationId();
        request.contextName = UserInfo.getOrganizationId();
        request.resource = UserInfo.getName();
        request.transactionId = 'T1';
        request.callback = CopadoQueueableTest.class;

        // Exercise
        Queue.block(UserInfo.getUserId());
        Queue.add(request);


        // Verify
        List<Queue__c> queue = [SELECT Id, Transaction__c, ContextId__c, Status__c, Resource__c  FROM Queue__c ORDER BY CreatedDate ASC];

        Assert.areEqual(1, queue.size(), 'Queue should have 1 record');
        Assert.areEqual('T1',  queue[0].Transaction__c, 'Resource name in queue should match');
        Assert.areEqual(UserInfo.getOrganizationId(),  queue[0].ContextId__c, 'Context Id in queue should match');
        Assert.areEqual(UserInfo.getName(),  queue[0].Resource__c, 'Resource name in queue should match');
        Assert.areEqual('In Progress',  queue[0].Status__c, 'Status of queue should be In Progress');
    }


    @IsTest
    private static void removeWithoutContextId() {
        // Setup
        Exception expectedException = null;
        String expectedErrorMessage = String.format(Label.MissingParameterValue, new List<String> {  'Context Id' } );


        // Exercise
        try {
            Queue.remove(new Set<Id>());
        } catch(Exception ex) {
            expectedException = ex;
        }


        // Verify
        Assert.isNotNull(expectedException, 'Invalid input to Queue.remove should throw an exception');
        Assert.areEqual(expectedErrorMessage,  expectedException.getMessage(), 'Exception message should specify all missing parameters');
    }


    @IsTest
    private static void removeInProgressJobFromQueue() {
        // Setup
        Exception expectedException = null;
        insert new Queue__c(Name = UserInfo.getUserId(), ContextId__c = UserInfo.getUserId(), Resource__c = UserInfo.getName(), Status__c = 'In Progress');


        // Exercise
        try {
            Queue.remove(UserInfo.getUserId());
        } catch(Exception ex) {
            expectedException = ex;
        }


        // Verify
        Assert.isNotNull(expectedException, 'Trying to call Queue.remove on an in progress job should throw an exception');
        Assert.areEqual(Label.JobInProgress,  expectedException.getMessage(), 'Exception message should match');
    }


    @IsTest
    private static void removeWithValidContextId() {
        // Setup
        insert new Queue__c(Name = UserInfo.getUserId(), ContextId__c = UserInfo.getUserId(), Resource__c = UserInfo.getName(), Status__c = 'Queued');


        // Exercise
        Queue.remove(UserInfo.getUserId());


        // Verify
        List<Queue__c> queue = [SELECT Id  FROM Queue__c];
        Assert.isTrue(queue.isEmpty(), 'No record should exist in queue');
    }


    @IsTest
    private static void releaseResourceWithInvalidInput() {
        // Setup
        Exception expectedException = null;


        // Exercise
        try {
            Queue.releaseResource(new Set<Id>());
        } catch(Exception ex) {
            expectedException = ex;
        }


        // Verify
        Assert.isNull(expectedException, 'should not throw any exception, if there is no job in queue matching the context id');
    }


    @IsTest
    private static void releaseResourceWithOneElementInTheQueue() {
        // Setup
        insert new Queue__c(Name = UserInfo.getUserId(), ContextId__c = UserInfo.getUserId(), Resource__c = UserInfo.getName(), Status__c = 'In Progress');


        // Exercise
        Queue.releaseResource(UserInfo.getUserId());


        // Verify
        List<Queue__c> queue = [SELECT Id  FROM Queue__c];
        Assert.isTrue(queue.isEmpty(), 'No record should exist in queue');
    }


    @IsTest
    private static void releaseResourceWithTwoElementInTheQueue() {
        // Setup
        Queue.AddRequest request1 = new Queue.AddRequest();
        request1.contextId = UserInfo.getUserId();
        request1.contextName = UserInfo.getUserId();
        request1.resource = UserInfo.getName();
        request1.callback = CopadoQueueableTest.class;
        Queue.add(request1);

        Queue.AddRequest request2 = new Queue.AddRequest();
        request2.contextId = UserInfo.getOrganizationId();
        request2.contextName = UserInfo.getOrganizationId();
        request2.resource = UserInfo.getName();
        request2.callback = CopadoQueueableTest.class;
        Queue.add(request2);


        // Exercise
        Test.startTest();
        Queue.releaseResource(UserInfo.getUserId());
        Test.getEventBus().deliver();
        Test.stopTest();
        Queue.ResumeRequest resumeRequest = new Queue.ResumeRequest();
        resumeRequest.action = 'Execute';
        resumeRequest.payload = request2.payload;
        resumeRequest.contextId = request2.contextId;
        resumeRequest.callback = request2.callback.getName();

        Queue.resume(new List<Queue.ResumeRequest> { resumeRequest });

        // Verify
        List<Queue__c> queue = [SELECT Id, ContextId__c, Status__c  FROM Queue__c];

        Assert.areEqual(1, queue.size(), '1 record should exist in queue');
        Assert.areEqual(UserInfo.getOrganizationId(), queue[0].ContextId__c, 'context Id should match');
        Assert.areEqual('In Progress', queue[0].Status__c, 'next element in queue should be in progress');
    }
}