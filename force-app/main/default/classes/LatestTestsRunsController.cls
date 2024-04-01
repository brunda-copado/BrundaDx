public with sharing class LatestTestsRunsController {
    // PUBLIC
    @AuraEnabled
    public static List<TestWrapper> getTests(Id parentId) {
        try {
            List<TestWrapper> result = new List<TestWrapper>();
            List<Test__c> tests = getLatestTestsRuns(parentId);
            Map<String, Result__c> consolidatedResultByLatestJobExecution = consolidatedResultByLatestJobExecution(tests);
            for (Test__c test : tests) {
                result.add(prepareWrapper(test, consolidatedResultByLatestJobExecution));
            }
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE
    private static List<Test__c> getLatestTestsRuns(Id parentId) {
        Set<String> testIds = new Set<String>();
        for (JobExecution__c jobExecution : [
            SELECT Id, DataJson__c
            FROM JobExecution__c
            WHERE Promotion__c = :parentId OR UserStoryCommit__c = :parentId OR Deployment__c = :parentId OR Deployment__r.Promotion__c = :parentId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ]) {
            DataJsonWrapper data = (DataJsonWrapper) JSON.deserialize(jobExecution.DataJson__c, DataJsonWrapper.class);
            if (data.testIds != null && !data.testIds.isEmpty()) {
                testIds.addAll(data.testIds);
            }
        }

        return getLatestTestsRuns(testIds);
    }

    private static List<Test__c> getLatestTestsRuns(Set<String> testIds) {
        return [
            SELECT
                Id,
                Name,
                Type__c,
                User_Story__c,
                ExtensionConfiguration__c,
                LatestJobExecution__c,
                ReadyToRun__c,
                ExtensionConfiguration__r.ExtensionTool__c,
                LatestJobExecution__r.Job_Step__c,
                LatestJobExecution__r.Job_Step__r.Result__c,
                (SELECT Id, Name, Status__c, Start_Time__c FROM Results__r ORDER BY Start_Time__c DESC)
            FROM Test__c
            WHERE Id IN :testIds
            WITH USER_MODE
        ];
    }

    private static Map<String, Result__c> consolidatedResultByLatestJobExecution(List<Test__c> tests) {
        Map<String, Result__c> resultByLatestJobExecution = new Map<String, Result__c>();
        Map<String, String> jobExecutionIdByResultId = new Map<String, String>();

        for (Test__c test : tests) {
            if (
                test.LatestJobExecution__c != null &&
                test.LatestJobExecution__r.Job_Step__c != null &&
                test.LatestJobExecution__r.Job_Step__r.Result__c != null
            ) {
                jobExecutionIdByResultId.put(test.LatestJobExecution__r.Job_Step__r.Result__c, test.LatestJobExecution__c);
            }
        }

        if (!jobExecutionIdByResultId.isEmpty()) {
            for (Result__c result : [
                SELECT Id, Name, Start_Time__c, Status__c
                FROM Result__c
                WHERE Id IN :jobExecutionIdByResultId.keyset()
                WITH USER_MODE
            ]) {
                resultByLatestJobExecution.put(jobExecutionIdByResultId.get(result.Id), result);
            }
        }
        return resultByLatestJobExecution;
    }

    private static TestWrapper prepareWrapper(Test__c test, Map<String, Result__c> consolidatedResultByLatestJobExecution) {
        return new TestWrapper()
            .id(test.id)
            .name(test.Name)
            .testType(test.Type__c)
            .testTool(test.ExtensionConfiguration__r.ExtensionTool__c)
            .testUrl()
            .result(test, consolidatedResultByLatestJobExecution);
    }

    //INNER

    public with sharing class DataJsonWrapper {
        public List<String> testIds;
    }
    public with sharing class TestWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String testType;
        @AuraEnabled
        public String testTool;
        @AuraEnabled
        public String runDate;
        @AuraEnabled
        public String result;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String testUrl;
        @AuraEnabled
        public String resultUrl;

        private TestWrapper id(String id) {
            this.id = id;
            return this;
        }

        private TestWrapper name(String name) {
            this.name = name;
            return this;
        }

        private TestWrapper testType(String testType) {
            this.testType = testType;
            return this;
        }

        private TestWrapper testTool(String testTool) {
            this.testTool = testTool;
            return this;
        }

        private TestWrapper status(Test__c test, String status) {
            this.status = status;

            return this;
        }

        private TestWrapper testUrl() {
            this.testUrl = '/' + this.id;
            return this;
        }

        private TestWrapper result(Test__c test, Map<String, Result__c> consolidatedResultByLatestJobExecution) {
            if (consolidatedResultByLatestJobExecution.containsKey(test.LatestJobExecution__c)) {
                Result__c result = consolidatedResultByLatestJobExecution.get(test.LatestJobExecution__c);
                this.runDate = result.Start_Time__c != null ? result.Start_Time__c.format() : '';
                this.result = result.Name;
                status(test, result.Status__c);
                this.resultUrl = '/' + result.Id;
            } else if (!test.Results__r.isEmpty()) {
                Result__c result = test.Results__r[0];
                this.runDate = result.Start_Time__c != null ? result.Start_Time__c.format() : '';
                this.result = result.Name;
                status(test, result.Status__c);
                this.resultUrl = '/' + result.id;
            } else {
                status(test, '');
            }
            return this;
        }
    }
}