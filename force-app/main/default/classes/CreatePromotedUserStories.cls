global with sharing class CreatePromotedUserStories {
    global class InvocableVariables {
        @InvocableVariable(label='User Story Ids' required=true)
        global List<Id> userStoryIds;
        @InvocableVariable(label='Promotion Id' required=false)
        global Id promotionId;
    }

    @InvocableMethod(label='Create Promoted User Stories' description='Creates promoted user stories under given Promotion record.')
    global static List<SObject> execute(List<InvocableVariables> variables) {
        InvocableVariables variable = variables[0];

        return new PromotedUserStoriesOperations(variable.userStoryIds, variable.promotionId).insertPromotedUserStories();
    }
}