public with sharing class TestExtensionMock implements Callable {
    // PUBLIC

    public Object call(String action, Map<String, Object> args) {
        List<Result__c> results;

        if (action == Label.ExecuteTestsAction) {
            results = mockTestExecution(parseTestsFrom(args));
        } else if (action == Label.ExecuteTestsAsAutomationAction) {
            results = mockTestExecution(parseTestsFrom(args));

            Id deploymentJobId = parseDeploymentJobIdFrom(args);
            updateDeploymentJob(deploymentJobId, results[0].Id);
        } else {
            throw new ApplicationException(Label.NoTestExtensionConfigured);
        }

        return results;
    }

    // PRIVATE

    private Id parseDeploymentJobIdFrom(Map<String, Object> args) {
        return (Id) new List<String>(args.keySet())[0];
    }

    private List<Test__c> parseTestsFrom(Map<String, Object> args) {
        List<Test__c> results = new List<Test__c>();

            for (Object obj : args.values()) {
            results.add((Test__c) obj);
        }

        return results;
    }

    private List<Result__c> mockTestExecution(List<Test__c> tests) {
        List<Result__c> results = new List<Result__c>();

        for (Test__c test : tests) {
                results.add(createMockResult(test.Id));
            }

            Utilities.Secure_DML(results, Utilities.DML_Action.INS, Schema.SObjectType.Result__c);

            return results;
        }

    private Result__c createMockResult(Id testId) {
        Result__c result = new Result__c(
            Job_Type__c = 'Mock Type',
            Progress_Status__c = 'Success',
            Status__c = 'Success',
            Start_Time__c = Datetime.now(),
            End_Time__c = Datetime.now(),
            Test__c = testId
        );

        return result;
    }

    private void updateDeploymentJob(Id deploymentJobId, Id resultId) {
        Deployment_Job__c job = new Deployment_Job__c(Id = deploymentJobId, Status__c = 'Success');
        Utilities.Secure_DML(job, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment_Job__c);

        JobAttachmentDetails attachmentDetail = new JobAttachmentDetails();
        attachmentDetail.m = 'Mock Successful Execution. Copado Test auto-completed the test, result: ' + resultId;
        attachmentDetail.l = 'INFO';
        attachmentDetail.t = '';

        Attachment jobTaskAttachment = new Attachment();
        jobTaskAttachment.Name = deploymentJobId + '.json';
        jobTaskAttachment.ParentId = deploymentJobId;
        jobTaskAttachment.Body = Blob.valueOf(JSON.serialize(new List<JobAttachmentDetails>{ attachmentDetail }));

        Utilities.Secure_DML(jobTaskAttachment, Utilities.DML_Action.INS, Schema.SObjectType.Attachment);
    }

    private class JobAttachmentDetails {
        public String m { get; set; }
        public String l { get; set; }
        public String t { get; set; }
    }
}