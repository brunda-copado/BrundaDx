public with sharing class CategorizeTests {
    private RunTestsAction.Request request;
    private Boolean isQgContext;
    private Map<String, TestTool__mdt> testToolByLabel;
    private String otherInformation;

    // CTOR

    public CategorizeTests(RunTestsAction.Request request, Boolean isQgContext, Map<String, TestTool__mdt> testToolByLabel) {
        this.request = request;
        this.isQgContext = isQgContext;
        this.testToolByLabel = testToolByLabel;
    }

    // Note: temporary constructor for services
    public CategorizeTests(Actions.RunTestRequest request, Boolean isQgContext, Map<String, TestTool__mdt> testToolByLabel) {
        this(getRequest(request), isQgContext, testToolByLabel);
        otherInformation = request.otherInformation;
    }

    // PUBLIC

    public TestsWrapper execute() {
        TestsWrapper result = new TestsWrapper();

        String extensionTool = getExtensionTool();

        List<Test__c> tests = getContextTests(extensionTool);
        result.add(categorizeByReadyToRun(tests));

        if (result.validTests.isEmpty() && (isQgContext || (String.isNotBlank(otherInformation)))) {
            List<Test__c> qualityGateTests = getQualityGateTests(extensionTool);
            result.add(categorizeByReadyToRun(qualityGateTests));
        }

        return result;
    }

    // PRIVATE

    private String getExtensionTool() {
        String extensionTool = request.tool;
        if (isQgContext) {
            ExtensionConfiguration__c extensionConfiguration = new ExtensionConfigurationsSelector()
                .byIds(new Set<Id>{ request.extensionConfigurationId })[0];
            extensionTool = extensionConfiguration.ExtensionTool__c;
        }
        return extensionTool;
    }

    private List<Test__c> getContextTests(String extensionTool) {
        return filterByTool(new TestsSelector().byParents(new Set<Id>(request.contextIds)), extensionTool);
    }

    private List<Test__c> filterByTool(List<Test__c> tests, String extensionTool) {
        List<Test__c> result = new List<Test__c>();

        for (Test__c test : tests) {
            if (testToolByLabel.containsKey(extensionTool) && test.ExtensionConfiguration__r.ExtensionTool__c == extensionTool) {
                result.add(test);
            }
        }

        return result;
    }

    private List<Test__c> getQualityGateTests(String extensionTool) {
        List<Test__c> result = new List<Test__c>();
        Id parentId = getJobExecutionParent();

        if (parentId != null) {
            String sObjectName = getSobjectName(parentId);

            if (sObjectName == 'Deployment__c') {
                result = filterByTool(getPromotionTests(parentId), extensionTool);
            } else {
                result = autoCreateTest(parentId, sObjectName, extensionTool);
            }
        }

        return result;
    }

    private TestsWrapper categorizeByReadyToRun(List<Test__c> tests) {
        TestsWrapper result = new TestsWrapper();
        for (Test__c test : tests) {
            if (test.ReadyToRun__c) {
                result.validTests.add(test.id);
            } else {
                result.ignoredTests.add(test.id);
            }
        }
        return result;
    }

    private Id getJobExecutionParent() {
        Id result;
        if (isQgContext) {
            Result__c consolidatedResult = new ResultsSelector().byId(request.resultId);
            result = new JobExecutionsSelector().byId(consolidatedResult.JobStep__r.JobExecution__c).ParentId__c;
        } else if (String.isNotBlank(otherInformation)) {
            RunTestOtherInformation otherInformationFromAutomation = (RunTestOtherInformation) JSON.deserialize(
                otherInformation,
                RunTestOtherInformation.class
            );
            result = otherInformationFromAutomation?.parentContextId;
        }
        return result;
    }

    private static String getSobjectName(Id recordId) {
        return recordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName();
    }

    private List<Test__c> getPromotionTests(Id deploymentId) {
        Id promotionId = new DeploymentsSelector().byId(new List<Id>{ deploymentId })[0].Promotion__c;
        return new TestsSelector().byParents(new Set<Id>{ promotionId });
    }

    private List<Test__c> autoCreateTest(Id parentId, String sObjectName, String extensionTool) {
        List<Test__c> result = new List<Test__c>();

        TestTool__mdt testTool = testToolByLabel.get(extensionTool);
        Id extensionConfiguration = request.extensionConfigurationId;

        for (Test__c existingTest : new TestsSelector().byParents(new Set<Id>{ parentId })) {
            if (existingTest.ExtensionConfiguration__c == extensionConfiguration && existingTest.Name.startsWith(testTool.MasterLabel + ' - ')) {
                result.add(existingTest);
            }
        }

        if (result.isEmpty()) {
            Test__c test = new AutoCreateTests(parentId, sObjectName).execute(extensionConfiguration, testTool);
            result.add(test);
        }

        return result;
    }

    // Note: converting service request to existing request
    private static RunTestsAction.Request getRequest(Actions.RunTestRequest request) {
        RunTestsAction.Request result = new RunTestsAction.Request();
        result.tool = request.tool;
        result.contextIds = request.contextIds;
        result.extensionConfigurationId = request.extensionConfigurationId;
        result.actionCallback = request.actionCallback;
        result.resultId = request.resultId;
        result.acceptanceCriteria = request.acceptanceCriteria;
        result.environmentId = request.environmentId;
        return result;
    }

    // INNER

    public with sharing class TestsWrapper {
        public List<Id> validTests;
        public List<Id> ignoredTests;

        public TestsWrapper() {
            validTests = new List<Id>();
            ignoredTests = new List<Id>();
        }

        public TestsWrapper add(TestsWrapper testWrapper) {
            validTests.addAll(testWrapper.validTests);
            ignoredTests.addAll(testWrapper.ignoredTests);
            return this;
        }
    }
}