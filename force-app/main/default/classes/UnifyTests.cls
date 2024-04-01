public with sharing class UnifyTests {
    private List<Id> userStoryIds;
    private Id destinationUserStoryId;

    // CTOR

    public UnifyTests(List<Id> userStoryIds, Id destinationUserStoryId) {
        this.userStoryIds = userStoryIds;
        this.destinationUserStoryId = destinationUserStoryId;
    }

    // PUBLIC

    public void execute() {
        Map<String, List<Test__c>> testsByTestTool = getTestsByTool();
        Map<String, UserStoryBundleTestsUnifier> unifierInstanceByTestTool = getUnifierByTool(testsByTestTool);
        Map<String, List<Test__c>> testsToInsertByTool = new Map<String, List<Test__c>>();
        List<Test__c> testsToClone = new List<Test__c>();
        for (String testTool : testsByTestTool.keySet()) {
            List<Test__c> toolTests = testsByTestTool.get(testTool);
            UserStoryBundleTestsUnifier unifier = unifierInstanceByTestTool.get(testTool);
            if (unifier != null) {
                List<Test__c> unifiedTests = unifier.unifyTests(toolTests);
                if (!unifiedTests.isEmpty()) {
                    testsToInsertByTool.put(testTool, unifiedTests);
                } else {
                    testsToClone.addAll(toolTests);
                }
            } else {
                testsToClone.addAll(toolTests);
            }
        }
        insertTests(testsToInsertByTool);
        for (String testTool : testsToInsertByTool.keySet()) {
            List<Test__c> unifiedTests = testsToInsertByTool.get(testTool);
            UserStoryBundleTestsUnifier unifier = unifierInstanceByTestTool.get(testTool);
            unifier.additionalLogicAfterUnify(unifiedTests);
        }
        cloneTests(testsToClone);
    }

    // PRIVATE

    private Map<String, List<Test__c>> getTestsByTool() {
        Map<String, List<Test__c>> testsByTestTool = new Map<String, List<Test__c>>();
        for (Test__c test : [
            SELECT
                Id,
                Name,
                OwnerId,
                Parent_Id__c,
                Priority__c,
                Promotion__c,
                ReadyToRun__c,
                Status__c,
                ExtensionConfiguration__c,
                Test_Tool__c,
                User_Story__c,
                AcceptanceCriteria__c,
                Application__c,
                Configuration__c,
                Feature__c,
                HasExtraConfiguration__c,
                LatestJobExecution__c
            FROM Test__c
            WHERE User_Story__c IN :userStoryIds
            WITH SECURITY_ENFORCED
        ]) {
            String testTool = test.Test_Tool__c;
            if (!testsByTestTool.containsKey(testTool)) {
                testsByTestTool.put(testTool, new List<Test__c>());
            }
            testsByTestTool.get(testTool).add(test);
        }
        return testsByTestTool;
    }

    private Map<String, UserStoryBundleTestsUnifier> getUnifierByTool(Map<String, List<Test__c>> testsByTestTool) {
        Map<String, UserStoryBundleTestsUnifier> unifierInstanceByTestTool = new Map<String, UserStoryBundleTestsUnifier>();
        for (TestTool__mdt testTool : new TestToolsSelector().byNames(new List<String>(testsByTestTool.keySet()))) {
            if (String.isNotBlank(testTool.UserStoryBundleTestsUnifierLogic__c)) {
                UserStoryBundleTestsUnifier unifier = getUnifierInstance(testTool.UserStoryBundleTestsUnifierLogic__c);
                unifierInstanceByTestTool.put(testTool.MasterLabel, unifier);
            }
        }
        return unifierInstanceByTestTool;
    }

    private UserStoryBundleTestsUnifier getUnifierInstance(String unifierClass) {
        String namespace = namespace(unifierClass);
        String className = name(unifierClass);

        Type result = Type.forName(namespace, className);
        if (result == null) {
            throw new ApplicationException(Label.Invalid_Class + unifierClass);
        }
        return ((UserStoryBundleTestsUnifier) result.newInstance());
    }

    private String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private String name(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

    private void insertTests(Map<String, List<Test__c>> testsToInsertByTool) {
        List<Test__c> testsToInsert = new List<Test__c>();
        for (String testTool : testsToInsertByTool.keySet()) {
            for (Test__c test : testsToInsertByTool.get(testTool)) {
                test.User_Story__c = destinationUserStoryId;
                testsToInsert.add(test);
            }
        }
        if (!testsToInsert.isEmpty()) {
            DML.safeInsert(
                testsToInsert,
                String.format(
                    Label.ErrorWhileInserting,
                    new List<String>{ Test__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(), 'UnifyTests.execute' }
                )
            );
        }
    }

    private void cloneTests(List<Test__c> testsToClone) {
        new CloneTests(testsToClone, destinationUserStoryId).execute();
    }
}