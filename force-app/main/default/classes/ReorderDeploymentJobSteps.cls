public with sharing class ReorderDeploymentJobSteps {

    Map<Id, JobStep__c> old;
    private List<JobStep__c> steps;
    private Set<Id> userStoryIds = new Set<Id>();

    private static final String AFTER = 'after';
    private static final String BEFORE = 'before';

    // CTOR

    public ReorderDeploymentJobSteps(List<JobStep__c> records, Map<Id, JobStep__c> old) {
        this.old = old;
        this.steps = filter(records);
    }

    // PUBLIC

    public void execute() {
        try {
            if(!steps.isEmpty()) {
                Map<Id, Double> maxBeforeOrderByUserStoryId = getUserStoriesWithMaxStepOrder(BEFORE);

                Map<Id, Double> maxAfterOrderByUserStoryId = getUserStoriesWithMaxStepOrder(AFTER);

                for (JobStep__c step : steps) {
                    Double maxOrder;

                    if (step.ExecutionSequence__c == BEFORE) {
                        maxOrder = maxBeforeOrderByUserStoryId.get(step.UserStory__c);
                    }
                    else if (step.ExecutionSequence__c == AFTER) {
                        maxOrder = maxAfterOrderByUserStoryId.get(step.UserStory__c);
                    }

                    step.Order__c = maxOrder != null ? maxOrder + 1 : 1;
                }
            }
        } catch(Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }

    // PRIVATE

    private List<JobStep__c> filter(List<JobStep__c> records) {
        List<JobStep__c> result = new List<JobStep__c>();

        for (JobStep__c step : records) {
            if (
                step.UserStory__c != null &&
                step.ExecutionSequence__c != old.get(step.Id).ExecutionSequence__c
            ) {
                result.add(step);
                userStoryIds.add(step.UserStory__c);
            }
        }

        return result;
    }


    private Map<Id, Double> getUserStoriesWithMaxStepOrder(String sequence) {
        Map<Id, Double> result = new Map<Id, Double>();

        List<AggregateResult> maxOrderSteps = [
            SELECT MAX(Order__c) maxOrder, UserStory__c userStoryId
            FROM JobStep__c
            WHERE UserStory__c IN :userStoryIds AND ExecutionSequence__c = :sequence
            WITH SECURITY_ENFORCED
            GROUP BY UserStory__c
        ];

        for (AggregateResult ar : maxOrderSteps) {
            result.put( (Id) ar.get('userStoryId'), (Double) ar.get('maxOrder') );
        }

        return result;
    }
}