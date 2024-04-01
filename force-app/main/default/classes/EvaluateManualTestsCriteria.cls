public with sharing class EvaluateManualTestsCriteria {
    private Id testId;
    private static final String PASSED = 'Passed';
    private static final String PASSED_WITH_COMMENTS = 'Passed with comments';
    private static final String FAILED = 'Failed';
    private static final String TEST_RUN_IN_PROGRESS = 'In progress';

    //CTOR

    public EvaluateManualTestsCriteria(Id testId) {
        this.testId = testId;
    }

    //PUBLIC

    public void execute() {
        try {
            Result__c result = getLatestResult();
            if (result != null && result.Status__c != FAILED) {
                List<CriteriaItem> criteria = getParsedAcceptanceCriteria();
                Map<Id, String> statusPerTester = getStatusPerTester();
                Map<Id, Set<Id>> groupMembersPerGroup = getGroupMembersPerGroup(getGroupIdsFrom(criteria));
                List<CriteriaValidation> validationWrapper = prepareValidationWrapper(criteria);
                String finalResultStatus = new ManualTestsEvaluationStatus(statusPerTester, validationWrapper, groupMembersPerGroup).execute();
                new ManualTestsResult(null, result).upsertResult(finalResultStatus);
            }
        } catch (Exception e) {
            throw new ApplicationException(Label.NODATATODISPLAY);
        }
    }

    //PRIVATE

    private String getAcceptanceCriteriaJson() {
        String result = new TestsSelector().byIds(new Set<Id>{ testId })[0].AcceptanceCriteria__c;

        return result;
    }

    private List<CriteriaItem> getParsedAcceptanceCriteria() {
        String acceptanceCriteria = getAcceptanceCriteriaJson();

        return (List<CriteriaItem>) JSON.deserialize(acceptanceCriteria.unescapeUnicode(), List<CriteriaItem>.class);
    }

    private Map<Id, String> getStatusPerTester() {
        return getCombinedTestRunStatusPerTester(getTestRuns());
    }

    private List<Test_Run__c> getTestRuns() {
        Result__c latestFinalResult = new ResultsSelector().getLatestFinalResultByTestId(testId);
        List<Test_Run__c> allTestRuns = new List<Test_Run__c>();

        if (latestFinalResult != null) {
            allTestRuns = new TestRunsSelector().createdAfterbyTestId(testId, latestFinalResult.LastModifiedDate);
        } else {
            allTestRuns = new TestRunsSelector().byTestId(testId);
        } 

        Set<Test_Run__c> uniqueRuns = new Set<Test_Run__c>();
        for (Test_Run__c testRun : allTestRuns) {
            if ( searchForTester(allTestRuns, testRun) && searchForScript(allTestRuns, testRun) ) {
                uniqueRuns.add(testRun);
            }
        }

        return new List<Test_Run__c>(uniqueRuns);
    }

    private Boolean searchForTester(List<Test_Run__c> searchList, Test_Run__c run) {
        
        Map<Id, Test_Run__c> testRunsById = new Map<Id, Test_Run__c>(searchList);
        
        if (testRunsById.get(run.Id) != null && testRunsById.get(run.Id).Tester__c == run.Tester__c) {
            return true;
        }
        
        return false;
    }

    private Boolean searchForScript(List<Test_Run__c> searchList, Test_Run__c run) {
        Map<Id, Test_Run__c> testRunsById = new Map<Id, Test_Run__c>(searchList);
        
        if (testRunsById.get(run.Id) != null && testRunsById.get(run.Id).Test_Script__c == run.Test_Script__c) {
            return true;
        }
        
        return false;
    }

    private Map<Id, String> getCombinedTestRunStatusPerTester(List<Test_Run__c> testRuns) {
        Map<Id, String> result = new Map<Id, String>();

        for (Test_Run__c testRun : testRuns) {
            String status = convertStatus(testRun.Status__c);

            if (!result.containsKey(testRun.Tester__c) || isStatusChangeRequired(status, result.get(testRun.Tester__c))) {
                result.put(testRun.Tester__c, status);
            }
        }
        return result;
    }

    private Boolean isStatusChangeRequired(String newStatus, String statusFromMap) {
        return (newStatus == FAILED && statusFromMap != FAILED) || (newStatus == TEST_RUN_IN_PROGRESS && statusFromMap == PASSED);
    }

    private static String convertStatus(String status) {
        return status == PASSED_WITH_COMMENTS ? PASSED : status;
    }

    private Set<Id> getGroupIdsFrom(List<CriteriaItem> criteria) {
        Set<Id> result = new Set<Id>();
        for (CriteriaItem criteriaRow : criteria) {
            if (String.valueOf(criteriaRow.tester.id).startsWith('00G')) {
                result.add(criteriaRow.tester.id);
            }
        }

        return result;
    }

    private Map<Id, Set<Id>> getGroupMembersPerGroup(Set<Id> groupIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        List<GroupMember> groupMembers = new List<GroupMember>();

        groupMembers = [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN :groupIds WITH SECURITY_ENFORCED];

        for (GroupMember member : groupMembers) {
            if (result.containsKey(member.GroupId)) {
                result.get(member.GroupId).add(member.UserOrGroupId);
            } else {
                result.put(member.GroupId, new Set<Id>{ member.UserOrGroupId });
            }
        }

        return result;
    }

    private List<CriteriaValidation> prepareValidationWrapper(List<CriteriaItem> acceptanceCriteria) {
        List<CriteriaValidation> result = new List<CriteriaValidation>();

        for (CriteriaItem criteriaRow : acceptanceCriteria) {
            CriteriaValidation validationRow = new CriteriaValidation();

            validationRow.memberId = criteriaRow.tester.id;
            validationRow.minimumTesters = criteriaRow.minimumTesters;
            validationRow.type = criteriaRow.type;

            result.add(validationRow);
        }

        return result;
    }

    private Result__c getLatestResult() {
        return new ResultsSelector().getLatestResultByTestId(testId);
    }

    //INNER

    private class CriteriaItem {
        private String testerScope;
        private Tester tester;
        private String type;
        private Integer minimumTesters;
    }

    private class Tester {
        private Id id;
    }

    public class CriteriaValidation {
        public Id memberId;
        public Integer minimumTesters;
        public Integer availableTesters = 0;
        public String status;
        public String type;
    }
}