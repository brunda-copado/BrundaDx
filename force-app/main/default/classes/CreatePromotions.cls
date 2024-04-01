global with sharing class CreatePromotions {
    global class InvocableVariables {
        @InvocableVariable(label='Project Id' required=false)
        global Id projectId;
        @InvocableVariable(label='Release Id' required=false)
        global Id releaseId;
        @InvocableVariable(label='Source Environment Id' required=true)
        global Id sourceEnvironmentId;
        @InvocableVariable(label='Destination Environment Id' required=true)
        global Id destinationEnvironmentId;
        @InvocableVariable(label='Back Promotion' required=true)
        global Boolean backPromotion;
        @InvocableVariable(label='Order User Stories By' required=false)
        global String orderUserStoriesBy;
    }

    @InvocableMethod(label='Create Promotion' description='Creates promotion record and returns it.')
    global static List<SObject> execute(List<InvocableVariables> variables) {
        InvocableVariables variable = variables[0];

        return new List<SObject> {
            new PromotionOperations(variable.sourceEnvironmentId, variable.destinationEnvironmentId, variable.backPromotion)
                .projectId(variable.projectId)
                .releaseId(variable.releaseId)
                .orderUserStoriesBy(variable.orderUserStoriesBy)
                .insertPromotion()
        };
    }

}