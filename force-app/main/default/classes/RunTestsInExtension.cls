public with sharing class RunTestsInExtension {
    private static final String COPADO_ROBOTIC_TESTING = 'Copado Robotic Testing';
    private List<Test__c> tests;

    // CTOR

    public RunTestsInExtension(List<Test__c> tests) {
        this.tests = tests;
    }

    // PUBLIC

    public void executeAsync() {
        Database.executeBatch(new RunTestsJob(tests, null), 1);
    }

    public List<JobExecution__c> execute() {
        return delegateToJobTemplate(tests);
    }

    public List<JobExecution__c> executeAsAutomation(Id deploymentJobId) {
        List<JobExecution__c> results = new List<JobExecution__c>();
        results = delegateToJobTemplate(tests, deploymentJobId);
        if (!results.isEmpty() && isFailedJobExecution(results[0])) {
            updateFailedDeploymentJob(deploymentJobId, Label.NoTestExtensionConfigured);
        }

        return results;
    }

    public List<String> getTestTools() {
        List<String> result = new List<String>();

        List<TestTool__mdt> testTools = new TestToolsSelector().getAll();
        for (TestTool__mdt testTool : testTools) {
            result.add(testTool.MasterLabel);
        }

        return result;
    }

    public void updateFailedDeploymentJob(Id deploymentJobId, String errorMessage) {
        Deployment_Job__c job = new Deployment_Job__c(Id = deploymentJobId, Status__c = 'Failed');
        Utilities.Secure_DML(job, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Job__c);

        JobAttachmentDetails attachmentDetail = new JobAttachmentDetails();
        attachmentDetail.m = errorMessage;
        attachmentDetail.l = 'INFO';
        attachmentDetail.t = '';

        Attachment jobTaskAttachment = new Attachment();
        jobTaskAttachment.Name = deploymentJobId + '.json';
        jobTaskAttachment.ParentId = deploymentJobId;
        jobTaskAttachment.Body = Blob.valueOf(JSON.serialize(new List<JobAttachmentDetails>{ attachmentDetail }));

        Utilities.Secure_DML(jobTaskAttachment, Utilities.DML_Action.INS, Schema.SObjectType.Attachment);
    }

    // PRIVATE

    private List<JobExecution__c> delegateToJobTemplate(List<Test__c> tests) {
        List<String> testToolsAvailable = getTestTools();

        List<RunTestsAction.Request> requests = new List<RunTestsAction.Request>();
        for (Test__c test : tests) {
            String tool = testToolsAvailable.contains(test.ExtensionConfiguration__r.ExtensionTool__c)
                ? test.ExtensionConfiguration__r.ExtensionTool__c
                : '';
            requests.add(new RunTestsAction.Request().tool(tool).context(new List<Id>{ test.Id }).acceptanceCriteria(test.AcceptanceCriteria__c));
        }

        List<RunTestsAction.Response> responses = RunTestsAction.execute(requests);

        return executionsFrom(responses);
    }

    private List<JobExecution__c> delegateToJobTemplate(List<Test__c> tests, Id environmentId) {
        List<String> testToolsAvailable = getTestTools();
        List<RunTestsAction.Request> requests = new List<RunTestsAction.Request>();

        // Hardcoded check for copado CRT extension tool because for classic version we are expecting
        // the tests which are selected on Connection Behaviour Automation Record Page belongs to same CRT tool
        List<Id> testIds = new List<Id>();
        for (Test__c test : tests) {
            if (test.ExtensionConfiguration__r.ExtensionTool__c == COPADO_ROBOTIC_TESTING) {
                testIds.add(test.Id);
            } else {
                String tool = testToolsAvailable.contains(test.ExtensionConfiguration__r.ExtensionTool__c)
                    ? test.ExtensionConfiguration__r.ExtensionTool__c
                    : '';
                requests.add(
                    new RunTestsAction.Request()
                        .tool(tool)
                        .context(new List<Id>{ test.Id })
                        .environment((String) environmentId)
                        .acceptanceCriteria(test.AcceptanceCriteria__c)
                );
            }
        }

        if (!testIds.isEmpty()) {
            RunTestsAction.Request request = new RunTestsAction.Request()
                .tool(COPADO_ROBOTIC_TESTING)
                .context(testIds)
                .environment((String) environmentId);
            requests.add(request);
        }

        List<RunTestsAction.Response> responses = RunTestsAction.execute(requests);
        return executionsFrom(responses);
    }

    private static boolean isFailedJobExecution(JobExecution__c result) {
        return result.Status__c == 'Error' && result.errorMessage__c != null ? true : false;
    }

    private static List<JobExecution__c> executionsFrom(List<RunTestsAction.Response> responses) {
        List<JobExecution__c> result = new List<JobExecution__c>();

        for (RunTestsAction.Response response : responses) {
            result.add(response.jobExecution);
        }

        return result;
    }

    private class JobAttachmentDetails {
        public String m { get; set; }
        public String l { get; set; }
        public String t { get; set; }
    }
}