public with sharing class ManualTestsEvaluationStatus {
    private Map<Id, String> statusPerTester = new Map<Id, String>();
    private List<EvaluateManualTestsCriteria.CriteriaValidation> validationWrapper = new List<EvaluateManualTestsCriteria.CriteriaValidation>();
    private Map<Id, Set<Id>> groupMembersPerGroup = new Map<Id, Set<Id>>();

    private static final String FAILED = 'Failed';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String REQUIRED = 'Required';
    private static final String SUCCESS = 'Success';
    private static final String TEST_RUN_IN_PROGRESS = 'In progress';
    private static final String PASSED = 'Passed';

    //CTOR

    public ManualTestsEvaluationStatus(
        Map<Id, String> statusPerTester,
        List<EvaluateManualTestsCriteria.CriteriaValidation> validationWrapper,
        Map<Id, Set<Id>> groupMembersPerGroup
    ) {
        this.statusPerTester = statusPerTester;
        this.validationWrapper = validationWrapper;
        this.groupMembersPerGroup = groupMembersPerGroup;
    }

    //PUBLIC

    public String execute() {
        List<EvaluateManualTestsCriteria.CriteriaValidation> updatedValidationWrapper = updateValidationWrapper();
        return getFinalStatus(updatedValidationWrapper);
    }

    //PRIVATE

    private List<EvaluateManualTestsCriteria.CriteriaValidation> updateValidationWrapper() {
        for (Id userId : statusPerTester.keySet()) {
            for (EvaluateManualTestsCriteria.CriteriaValidation validationRow : validationWrapper) {
                if (userId == validationRow.memberId || isUserFromGroup(userId, validationRow.memberId)) {
                    validationRow.availableTesters++;
                    validationRow.status = getValidationStatus(validationRow.status, statusPerTester.get(userId));
                }
            }
        }
        return validationWrapper;
    }

    private Boolean isUserFromGroup(Id userId, Id validationMemberId) {
        return groupMembersPerGroup.containsKey(validationMemberId) && groupMembersPerGroup.get(validationMemberId).contains(userId);
    }

    private String getValidationStatus(String oldStatus, String newStatus) {
        return oldStatus != PASSED && oldStatus != null ? oldStatus : newStatus;
    }

    private String getFinalStatus(List<EvaluateManualTestsCriteria.CriteriaValidation> validationData) {
        String result;
        Set<String> testersStatus = new Set<String>();

        for (EvaluateManualTestsCriteria.CriteriaValidation validationRow : validationData) {
            if (validationRow.status == FAILED) {
                result = FAILED;
                break;
            } else if (isInProgress(validationRow)) {
                result = IN_PROGRESS;
                break;
            } else if (isPassed(validationRow)) {
                testersStatus.add(validationRow.status);
            }
        }

        result = checkIfAllPassed(result, testersStatus);
        return result;
    }

    private Boolean isInProgress(EvaluateManualTestsCriteria.CriteriaValidation validationRow) {
        return validationRow.status == TEST_RUN_IN_PROGRESS ||
            (validationRow.availableTesters < validationRow.minimumTesters &&
            validationRow.type == REQUIRED);
    }

    private Boolean isPassed(EvaluateManualTestsCriteria.CriteriaValidation validationRow) {
        return validationRow.availableTesters >= validationRow.minimumTesters && validationRow.type == REQUIRED;
    }

    private String checkIfAllPassed(String result, Set<String> testersStatus) {
        return result == null && testersStatus.size() == 1 && testersStatus.contains(PASSED) ? SUCCESS : result;
    }
}