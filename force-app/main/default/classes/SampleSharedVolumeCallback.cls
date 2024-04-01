public class SampleSharedVolumeCallback implements JobExecutionCallback {

    public void execute(JobExecution__c job, String status) {
        CreateExecution.Request request = new CreateExecution.Request();
        request.runAfterInstantiation = true;
        request.transactionId = '1234567890';
        //request.parentId = 'a0T09000000lQZgEAM';
        request.templateName = 'TS2_1';
        //request.callback = 'SampleJobFinishCallback';
        CreateExecution.execute(new List<CreateExecution.Request> { request });
    }
}