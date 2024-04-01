@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class RunTestsExecutionPayload {
    // PUBLIC

    public List<Id> testIds;

    public List<Id> ignoredTestIds;

    public String environmentId;

    public String actionCallback;

    public Id resultId;

    public List<Id> resultIds;

    public String acceptanceCriteria;

    public Id extensionConfigurationId;

    public Id qualityCheck;

    public Id parentContextId;
    public Id parentJobExecutionId;

    public RunTestsExecutionPayload tests(List<Id> ids) {
        testIds = ids;
        return this;
    }

    public RunTestsExecutionPayload ignoredTests(List<Id> ids) {
        ignoredTestIds = ids;
        return this;
    }

    public RunTestsExecutionPayload environment(String id) {
        environmentId = id;
        return this;
    }

    public RunTestsExecutionPayload callback(String className) {
        actionCallback = className;
        return this;
    }

    public RunTestsExecutionPayload result(Id id) {
        resultId = id;
        return this;
    }

    public RunTestsExecutionPayload results(List<Id> ids) {
        resultIds = ids;
        return this;
    }

    public RunTestsExecutionPayload acceptanceCriteria(String json) {
        acceptanceCriteria = json;
        return this;
    }

    public RunTestsExecutionPayload extensionConfigurationId(Id id) {
        extensionConfigurationId = id;
        return this;
    }

    public RunTestsExecutionPayload qualityCheck(Id qualityCheck) {
        this.qualityCheck = qualityCheck;
        return this;
    }

    public RunTestsExecutionPayload parentContextId(Id parentContextId) {
        this.parentContextId = parentContextId;
        return this;
    }

    public RunTestsExecutionPayload parentJobExecutionId(Id parentJobExecutionId) {
        this.parentJobExecutionId = parentJobExecutionId;
        return this;
    }
}