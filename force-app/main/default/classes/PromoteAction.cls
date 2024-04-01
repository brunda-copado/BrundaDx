@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PromoteAction extends PromoteActionService implements JobExecutionCallback {
    // GLOBAL

    @InvocableMethod(label='Run a Copado promote' description='' category='Copado Multi-Cloud')
    global static List<Response> promote(List<Request> requests) {
        Actions.PromotionRequest promoteRequest = convertRequests(requests);
        Actions.PromotionResult promoteResult = Actions.PromotionService.execute(promoteRequest);
        return convertResult(promoteResult);
    }

    global void execute(JobExecution__c job, String status) {
        new PromotionServiceImpl().execute(job, status);
    }

    // PRIVATE

    private static Actions.PromotionRequest convertRequests(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }
        Request request = getRequest(requests);

        Actions.PromotionRequest result = new Actions.PromotionRequest();
        result.promotionId = request.promotionId;
        result.userStoryIds = request.userStoryIds;
        result.executePromotion = request.executePromotion;
        result.executeDeployment = request.executeDeployment;
        result.deploymentDryRun = request.deploymentDryRun;
        result.otherInformation = request.otherInformation;
        result.sourceEnvironmentId = request.sourceEnvironmentId;
        result.projectId = request.projectId;
        result.isBackPromotion = request.isBackPromotion;
        result.actionCallback = request.actionCallback;
        return result;
    }

    private static Request getRequest(List<Request> requests) {
        Request result = requests[0];
        result.executePromotion = result.executePromotion != null ? result.executePromotion : true;
        result.executeDeployment = result.executeDeployment != null ? result.executeDeployment : false;
        result.deploymentDryRun = result.deploymentDryRun != null ? result.deploymentDryRun : false;
        result.isBackPromotion = result.isBackPromotion != null ? result.isBackPromotion : false;
        return result;
    }

    private static List<Response> convertResult(Actions.PromotionResult promoteResult) {
        Response result = new Response();
        result.jobExecution = promoteResult.jobExecution;
        result.promotion = promoteResult.promotion;
        return new List<Response>{ result };
    }

    // INNER

    global class Request {
        @InvocableVariable(
            label='Promotion Id'
            description='Id of the Promotion record. If it is not defined, Copado will create a new promotion with the parameter values provided.'
        )
        global Id promotionId;
        @InvocableVariable(label='User Story Ids' description='Ids of the user stories to be included in the promotion.')
        global List<Id> userStoryIds = new List<Id>();
        @InvocableVariable(label='Execute Promotion' description='Include this parameter if you want to run the promote job template.')
        global Boolean executePromotion = true;
        @InvocableVariable(
            label='Execute Deployment'
            description='Include this parameter if you want to run the deploy job template after the promote job template execution.'
        )
        global Boolean executeDeployment = false; // this is for promote+deplos US, validate US, and validate promotion
        @InvocableVariable(label='Deployment Dry Run' description='Include this parameter if you want to perform a validation-only deployment.')
        global Boolean deploymentDryRun = false; // NOTE: this is "validate only", but more generic for other technologies
        @InvocableVariable(label='Other Information' description='Additional information that can be passed for the job execution in JSON format')
        global String otherInformation; // "other information" in json, additional values associated with this commit
        @InvocableVariable(
            label='Source Environment Id'
            description='Id of the promotion’s source environment. Copado will use this parameter to populate the destination environment if no promotion Id is specified.'
        )
        global Id sourceEnvironmentId;
        @InvocableVariable(
            label='Project Id'
            description='Id of the Project record that will be used to define the pipeline details and pipeline connections.'
        )
        global Id projectId;
        @InvocableVariable(label='Back Promotion' description='Include this parameter if the promotion that will be executed is a back-promotion.')
        global Boolean isBackPromotion = false;
        @InvocableVariable(label='Action Callback' description='Apex Callback Class that implements JobExecutionCallback')
        global String actionCallback;
    }

    global class Response {
        @InvocableVariable
        global JobExecution__c jobExecution;
        @InvocableVariable
        global Promotion__c promotion;
    }
}