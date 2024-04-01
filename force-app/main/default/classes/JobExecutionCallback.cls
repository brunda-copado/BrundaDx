global interface JobExecutionCallback {
    void execute(JobExecution__c job, String status);
}