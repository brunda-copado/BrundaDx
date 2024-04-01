public with sharing class WorkSubmitService implements CLIInterface {
    private User_Story__c userStory;
    private final static String ACTION_VALIDATE = 'validate';
    private final static String ACTION_PROMOTE = 'promote';
    private final static String ACTION_DEPLOY = 'deploy';

    // PUBLIC

    public String run(CliProxy.CLIWrapper record) {
        String result = null;
        assertOLS();

        String requestedAction = record.operation.toLowerCase();
        SubmitServiceWrapper params = (SubmitServiceWrapper) JSON.deserialize(record.body, SubmitServiceWrapper.class);

        List<User_Story__c> userStoryList = [
            SELECT
                Id,
                Name,
                Promote_and_Deploy__c,
                Promote_Change__c,
                Last_Validation_Promotion__c,
                Project__c,
                Release__c,
                Environment__c,
                Promote_as_Single_Step__c,
                Promotion_Test_Level__c,
                Org_Credential__c,
                Platform__c
            FROM User_Story__c
            WHERE Id = :params.usId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (userStoryList.isEmpty()) {
            // Note: This case of no user story found is handled by CLI client
            result = JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.OK.name(), null));
        }
        userStory = userStoryList[0];

        if (requestedAction == ACTION_VALIDATE) {
            result = validate();
        } else if (requestedAction == ACTION_PROMOTE || requestedAction == ACTION_DEPLOY) {
            result = promoteDeploy(requestedAction);
        } else {
            throw new ApplicationException(Label.UnSupportedOperation);
        }

        return result;
    }

    // PRIVATE

    private String promoteDeploy(String action) {
        WorkSubmitDataWrapper result = new WorkSubmitDataWrapper(userStory);
        if (action == ACTION_PROMOTE) {
            assertFLSPromoteDeploy(action);
            userStory.Promote_Change__c = true;
            Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
        } else if (action == ACTION_DEPLOY && isSalesforcePlatform()) {
            assertFLSPromoteDeploy(action);
            userStory.Promote_and_Deploy__c = true;
            Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
        } else if (action == ACTION_DEPLOY && !isSalesforcePlatform()) {
            assertFLSPromoteDeploy(action);
            userStory.Promote_and_Deploy__c = true;

            UserStories.bypassTrigger = true;
            Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
            UserStories.bypassTrigger = false;

            List<PromoteAction.Response> responseList = multiCloudPromote();
            result.jobExecutionId = responseList[0].jobExecution.Id;
        }

        return (JSON.serialize(result));
    }

    private String validate() {
        WorkSubmitDataWrapper result = new WorkSubmitDataWrapper();

        if (isSalesforcePlatform()) {
            assertFLSValidation();
            Id promotionId = validateClassic();
            result.message = successMessage(promotionId);
        } else {
            List<PromoteAction.Response> responseList = multiCloudValidate();
            Id promotionId = responseList[0].jobExecution.Promotion__c;
            result.message = successMessage(promotionId);
            result.jobExecutionId = responseList[0].jobExecution.Id;
        }

        return (JSON.serialize(result));
    }

    private Boolean isSalesforcePlatform() {
        return (String.isBlank(userStory.Platform__c) || userStory.Platform__c == 'Salesforce');
    }

    private void assertFLSValidation() {
        List<String> checkFlsList = new List<String>();
        checkFlsList.addAll(
            CliSecurityService.checkFLS(
                Schema.SObjectType.Promotion__c.getName(),
                new List<String>{
                    Schema.SObjectType.Promotion__c.fields.Project__c.getName(),
                    Schema.SObjectType.Promotion__c.fields.Release__c.getName(),
                    Schema.SObjectType.Promotion__c.fields.Source_Org_Credential__c.getName(),
                    Schema.SObjectType.Promotion__c.fields.Source_Environment__c.getName(),
                    Schema.SObjectType.Promotion__c.fields.Send_Deployment_Complete_email__c.getName(),
                    Schema.SObjectType.Promotion__c.fields.Status__c.getName()
                },
                Utilities.DML_Action.INS
            )
        );

        checkFlsList.addAll(
            CliSecurityService.checkFLS(
                Schema.SObjectType.Promoted_User_Story__c.getName(),
                new List<String>{
                    Schema.SObjectType.Promoted_User_Story__c.fields.User_Story__c.getName(),
                    Schema.SObjectType.Promoted_User_Story__c.fields.Promotion__c.getName()
                },
                Utilities.DML_Action.INS
            )
        );

        checkFlsList.addAll(
            CliSecurityService.checkFLS(
                Schema.SObjectType.User_Story__c.getName(),
                new List<String>{
                    Schema.SObjectType.User_Story__c.fields.Last_Validation_Promotion__c.getName(),
                    Schema.SObjectType.User_Story__c.fields.Last_Validation_Deployment__c.getName()
                },
                Utilities.DML_Action.UPD
            )
        );

        if (!checkFlsList.isEmpty()) {
            throw new ApplicationException(Label.Insufficient_Access + checkFlsList);
        }
    }

    private Id validateClassic() {
        Promotion__c promotion = new Promotion__c();
        promotion.Project__c = userStory.Project__c;
        promotion.Release__c = userStory.Release__c;
        promotion.Source_Org_Credential__c = userStory.Org_Credential__c;
        promotion.Source_Environment__c = userStory.Environment__c;
        promotion.Send_Deployment_Complete_email__c = true;
        promotion.Status__c = 'Validation';
        Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.SObjectType.Promotion__c);

        Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id);
        pus.Name = 'Promoted User Story: ' + userStory.Name;
        Utilities.Secure_DML(pus, Utilities.DML_Action.INS, schema.SObjectType.Promoted_User_Story__c);

        userStory.Last_Validation_Promotion__c = promotion.Id;
        userStory.Last_Validation_Deployment__c = null;
        Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);

        DeployAPI.deployPromotionAsync(
            userStory.Last_Validation_Promotion__c,
            userStory.Name,
            true,
            userStory.Promote_as_Single_Step__c,
            userStory.Promotion_Test_Level__c
        );

        return promotion.Id;
    }

    private String successMessage(Id recordId) {
        return String.format(Label.PROMOTION_RECORD_CREATED_FOR_USER_STORY, new List<String>{ recordId, userStory.Id });
    }

    private List<PromoteAction.Response> multiCloudValidate() {
        return executePromoteAction(true);
    }

    private List<PromoteAction.Response> multiCloudPromote() {
        return executePromoteAction(false);
    }

    private List<PromoteAction.Response> executePromoteAction(Boolean isValidation) {
        PromoteAction.Request request = new PromoteAction.Request();
        request.projectId = userStory.Project__c;
        request.SourceEnvironmentId = userStory.Environment__c;
        request.userStoryIds.add(userStory.Id);
        request.executePromotion = true;
        request.executeDeployment = true;
        request.deploymentDryRun = isValidation;

        return PromoteAction.promote(new List<PromoteAction.Request>{ request });
    }

    private void assertOLS() {
        List<String> checkOlsList = CliSecurityService.checkOLS(new List<String>{ Schema.SObjectType.User_Story__c.getName() });

        if (!checkOlsList.isEmpty()) {
            throw new ApplicationException(Label.Insufficient_Access + checkOlsList);
        }
    }

    private void assertFLSPromoteDeploy(String action) {
        List<String> fieldList = new List<String>();

        if (action == ACTION_PROMOTE) {
            fieldList.add(Schema.SObjectType.User_Story__c.fields.Promote_Change__c.getName());
        } else if (action == ACTION_DEPLOY) {
            fieldList.add(Schema.SObjectType.User_Story__c.fields.Promote_and_Deploy__c.getName());
        }

        List<String> checkFlsList = CliSecurityService.checkFLS(Schema.SObjectType.User_Story__c.getName(), fieldList, Utilities.DML_Action.UPD);

        if (!checkFlsList.isEmpty()) {
            throw new ApplicationException(Label.Insufficient_Access + checkFlsList);
        }
    }

    // INNER

    @TestVisible
    private class SubmitServiceWrapper {
        public String usId;
    }

    @TestVisible
    private class WorkSubmitDataWrapper extends CliSfDataWrapper {
        public User_Story__c userStory;
        public Id jobExecutionId;

        public WorkSubmitDataWrapper() {
            status = CliSfDataWrapper.StatusResult.OK.name();
        }

        public WorkSubmitDataWrapper(User_Story__c us) {
            status = CliSfDataWrapper.StatusResult.OK.name();
            userStory = us;
        }

        public WorkSubmitDataWrapper(String msg) {
            status = CliSfDataWrapper.StatusResult.OK.name();
            message = msg;
        }
    }
}