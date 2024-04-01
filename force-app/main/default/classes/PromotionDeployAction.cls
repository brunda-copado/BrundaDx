@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PromotionDeployAction extends PromoteActionService implements JobExecutionCallback {
    // GLOBAL

    @InvocableMethod(label='Run a Copado promotion deployment' description='' category='Copado Multi-Cloud')
    global static List<Response> deploy(List<Request> requests) {
        Actions.PromotionDeploymentRequest deploymentRequest = convertRequests(requests);
        Actions.PromotionDeploymentResult deploymentResult = Actions.PromotionDeploymentService.execute(deploymentRequest);
        return convertResult(deploymentResult);
    }

    global void execute(JobExecution__c job, String status) {
        new PromotionDeploymentServiceImpl().execute(job, status);
    }

    // PRIVATE

    private static Actions.PromotionDeploymentRequest convertRequests(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }
        Request request = requests[0];

        Actions.PromotionDeploymentRequest result = new Actions.PromotionDeploymentRequest();
        result.promotionId = request.promotionId;
        result.deploymentDryRun = request.deploymentDryRun != null ? request.deploymentDryRun : false;
        result.otherInformation = request.otherInformation;
        result.actionCallback = request.actionCallback;
        return result;
    }

    private static List<Response> convertResult(Actions.PromotionDeploymentResult deploymentResult) {
        Response result = new Response();
        result.jobExecution = deploymentResult.jobExecution;
        return new List<Response>{ result };
    }

    // INNER

    global class Request {
        @InvocableVariable(
            required=true
            label='Promotion Id'
            description='Id of the Promotion record. Copado will create a new deployment with the parameter values provided.'
        )
        global Id promotionId;
        @InvocableVariable(label='Execute Deployment' description='Include this parameter if you want to run the deploy job template.')
        global boolean executeDeployment = true;
        @InvocableVariable(label='Deployment Dry Run' description='Include this parameter if you want to perform a validation-only deployment.')
        global boolean deploymentDryRun = false; // NOTE: this is "validate only", but more generic for other technologies
        @InvocableVariable(label='Other Information' description='Additional information that can be passed for the job execution in JSON format')
        global String otherInformation; // "other information" in json, additional values associated with this commit
        @InvocableVariable(label='Action Callback' description='Apex Callback Class that implements JobExecutionCallback')
        global String actionCallback;
    }

    global with sharing class Response {
        @InvocableVariable
        global JobExecution__c jobExecution;
    }
}