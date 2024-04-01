@SuppressWarnings('PMD.AvoidGlobalModifier')
// AvoidGlobalModifier: As we want to expose the services as global, thus the modifier
global inherited sharing class Quality implements CopadoDomain {
    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Quality Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static MatchingRulesResult matchingRules(MatchingRulesRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            return QualityServiceImpl.matchingRules(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Quality Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static StepsResult steps(StepsRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            return QualityServiceImpl.steps(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class MatchingRulesRequest implements CopadoServiceRequest {
        global String action; // Api name of the action to match against Quality Gate Rules
        global Id pipeline; // Id of the pipeline to match against Quality Gate Rule Conditions
        global String platform; // Platform name to match against Quality Gate Rule Conditions
        global String templateName; // Api name of the Job Template used. THIS IS NOT NEEDED AT THE MOMENT, BUT WE WILL LEAVE IT UNTIL ENFORCE() SERVICE IS COMPLETED AND THE LOGIC TO INJECT THE STEPS IN THE CORRECT ORDER IS FIXED
        global Id environment; // Id of the environment to match against Quality Gate Rule Conditions
        global List<Id> contextIds; // List of ids (e.g. user stories, promotions, etc.)
        global List<User_Story_Metadata__c> metadataChanges; // List of User Story Metadata records to match against Quality Gate Rule Conditions
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class MatchingRulesResult implements CopadoServiceResult {
        global Quality_Gate_Rule_Condition__c[] qualityGates; // Quality Gates Rules Conditions (including Quality Rule information) that match the given scope and criteria
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class StepsRequest implements CopadoServiceRequest {
        global String action; // Api name of the action to match against Quality Gate Rules
        global Id pipeline; // Id of the pipeline to match against Quality Gate Rule Conditions
        global String platform; // Platform name to match against Quality Gate Rule Conditions
        global String templateName; // Api name of the Job Template used. THIS IS NOT NEEDED AT THE MOMENT, BUT WE WILL LEAVE IT UNTIL ENFORCE() SERVICE IS COMPLETED AND THE LOGIC TO INJECT THE STEPS IN THE CORRECT ORDER IS FIXED
        global Id environment; // Id of the environment to match against Quality Gate Rule Conditions
        global List<Id> contextIds; // List of ids (e.g. user stories, promotions, etc.)
        global List<User_Story_Metadata__c> metadataChanges; // List of User Story Metadata records to match against Quality Gate Rule Conditions
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class StepsResult implements CopadoServiceResult {
        global List<Jobs.ExecutionStep> steps; // Step list to enforce them in a job execution
    }
}