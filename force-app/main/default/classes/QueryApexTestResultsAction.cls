public with sharing class QueryApexTestResultsAction { // NOPMD: Request and Result does not count as Excessive public items.
    private static final String APEX_CLASS_METADATA = 'ApexClass';
    private static final String APEX_TRIGGER_METADATA = 'ApexTrigger';

    public with sharing class Request {
        @InvocableVariable(label='User Story Id')
        public Id userStoryId;

        @InvocableVariable(label='Test Class Names')
        public String testClassNames;

        @InvocableVariable(label='Org Credential Id')
        public Id credentialId;

        @InvocableVariable(label='Test Execution Job Id')
        public String asyncJobId;
    }

    public with sharing class Result {
        @InvocableVariable(label='Result JSON')
        public String resultJson;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        public Result(String resultJson, Boolean isSuccess) {
            this.resultJson = resultJson;
            this.isSuccess = isSuccess;
        }
    }

    // PUBLIC

    @InvocableMethod(label='Query Apex Test Results' description='Run Apex Tests' category='Test')
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        try {
            Request request = requests[0];

            String credentialId = request.credentialId;
            String asyncJobId = request.asyncJobId;
            String userStoryId = request.userStoryId;
            String testClassNames = request.testClassNames;

            String status = new ApexTestsService(credentialId).queryRunStatus(asyncJobId);

            if (status == 'Completed') {
                ApexTestRunResult apexTestRunResult = new ApexTestsService(credentialId).queryResults(asyncJobId);
                AggregateCoverageResult aggregatedCoverageResult = new ApexCoverageService().queryResults(credentialId, userStoryId, testClassNames);

                Decimal usMinimumCoverage = getMinimumCoverage(userStoryId);

                results.add(
                    new Result(
                        JSON.serializePretty(createCompleteResult(apexTestRunResult, aggregatedCoverageResult, usMinimumCoverage))
                            .replaceAll('timeX', 'time'),
                        true
                    )
                );
            } else {
                results.add(new Result(null, true));
            }
        } catch (Exception ex) {
            results.add(new Result('', false));
        }

        return results;
    }

    // PRIVATE

    private static Decimal getMinimumCoverage(Id userStoryId) {
        Decimal result;

        List<User_Story__c> userStories = new UserStoriesSelector().byIds(new Set<Id>{ userStoryId });
        if (!userStories.isEmpty()) {
            result = userStories[0].Minimum_Apex_Code_Coverage__c;
        }

        return result;
    }

    private static ApexTestResultDto createCompleteResult(
        ApexTestRunResult apexTestRunResult,
        AggregateCoverageResult aggregatedCoverageResult,
        Decimal usMinimumCoverage
    ) {
        ApexTestResultDto result = new ApexTestResultDto();

        result.details = Label.ApexTestExecutionDetails;
        result.failures = apexTestRunResult.getNumberOfFailures();
        result.timeX = apexTestRunResult.getTotalExecutionTime();
        result.tests = apexTestRunResult.records.size();
        result.errors = result.failures > 0;

        result.testClassResults = formatApexTestResultsByTestClass(apexTestRunResult);
        result.classCoverageResults = formatCoverageResultsByFile(aggregatedCoverageResult, APEX_CLASS_METADATA);
        result.triggerCoverageResults = formatCoverageResultsByFile(aggregatedCoverageResult, APEX_TRIGGER_METADATA);

        result.userStoryCoverage = (Integer) aggregatedCoverageResult?.calculateCoveragePercentage();
        result.coverageWarning = result.userStoryCoverage < 75
            ? String.format(Label.CoverageWarning, new List<String>{ String.valueOf((Integer) (result.userStoryCoverage)) + '%' })
            : '';
        result.failingMethods = result.failures;
        result.classesWithoutCoverage = aggregatedCoverageResult?.calculateMetadataFilesWithoutCoverage(usMinimumCoverage, APEX_CLASS_METADATA);
        result.triggersWithoutCoverage = aggregatedCoverageResult?.calculateMetadataFilesWithoutCoverage(usMinimumCoverage, APEX_TRIGGER_METADATA);

        return result;
    }

    private static Map<String, TestClassResult> formatApexTestResultsByTestClass(ApexTestRunResult apexTestRunResult) {
        Map<String, TestClassResult> result = new Map<String, TestClassResult>();

        for (ApexTestRunResult.TestMethodResult testMethodResult : apexTestRunResult.records) {
            TestClassResult classResult = result.get(testMethodResult.ApexClass.Name);

            TestMethodResult methodResult = new TestMethodResult();
            methodResult.name = testMethodResult.MethodName;
            methodResult.success = testMethodResult.Outcome == 'Pass' ? true : false;
            methodResult.message = testMethodResult.Message != null ? testMethodResult.Message : '';

            if (classResult == null) {
                classResult = new TestClassResult();
                classResult.methods = new List<TestMethodResult>();
            }

            classResult.methods.add(methodResult);
            result.put(testMethodResult.ApexClass.Name, classResult);
        }

        return result;
    }

    private static Map<String, ClassCoverageResult> formatCoverageResultsByFile(
        AggregateCoverageResult aggregateCoverageResult,
        String metadataType
    ) {
        Map<String, ClassCoverageResult> result = new Map<String, ClassCoverageResult>();

        if (aggregateCoverageResult != null) {
            for (AggregateCoverageResult.FileCoverageResult coverageResult : aggregateCoverageResult.records) {
                if (coverageResult.ApexClassOrTrigger.attributes.url.contains(metadataType) && 
                    coverageResult.NumLinesCovered + coverageResult.NumLinesUncovered > 0) {
                    ClassCoverageResult classCoverageResult = new ClassCoverageResult();

                    classCoverageResult.numLocationsNotCovered = coverageResult.NumLinesUncovered;
                    classCoverageResult.numLocations = coverageResult.NumLinesCovered + coverageResult.NumLinesUncovered;
                    classCoverageResult.coverage = coverageResult.calculateFileCoveragePercentage();	
                    result.put(coverageResult.ApexClassOrTrigger.Name, classCoverageResult);	
                }
            }
        }

        return result;
    }

    // INNER CLASSES

    @TestVisible
    private class ApexTestResultDto {
        public String details;
        public String coverageWarning;

        public Integer tests;
        public Integer failures;
        public Integer failingMethods;
        // Note: "time" is a reserved identifier, therefore we use "timeX" and later replace by "time" in the resulting Json.
        public Integer timeX;
        public Integer classesWithoutCoverage;
        public Integer triggersWithoutCoverage;

        public Double userStoryCoverage;

        public Boolean errors;

        public Map<String, TestClassResult> testClassResults;
        public Map<String, ClassCoverageResult> classCoverageResults;
        public Map<String, ClassCoverageResult> triggerCoverageResults;
    }

    private class TestClassResult {
        public List<TestMethodResult> methods;
    }

    private class TestMethodResult {
        public String name;
        public Boolean success;
        public String message;
    }

    private class ClassCoverageResult {
        public Integer numLocations;
        public Integer numLocationsNotCovered;
        public Double coverage;
    }
}