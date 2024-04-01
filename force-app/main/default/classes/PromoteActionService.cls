// note: methods are static and being used by child classes from static methods.
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing virtual class PromoteActionService {
    public static final String IN_PROGRESS = 'In Progress';
    public static final String SUCCESSFUL = 'Successful';
    public static final String COMPLETED = 'Completed';
    public static final String COMPLETED_SUCCESSFULLY = 'Completed Successfully';
    public static final String COMPLETED_WITH_ERRORS = 'Completed with errors';
    public static final String MERGE_CONFLICT = 'Merge Conflict';
    public static final String VALIDATED = 'Validated';
    public static final String VALIDATION_FAILED = 'Validation failed';

    // PUBLIC

    public static void populateUserStoryParameters(CreateExecutionRequestData requestData, Promotion__c promotion) {
        List<Id> userStoryIds = new List<Id>();
        List<String> userStoryBranches = new List<String>();
        for (User_Story__c userStory : getUserStoriesInOrder(promotion)) {
            userStoryIds.add(userStory.Id);
            userStoryBranches.add('feature/' + userStory.Name);
        }
        requestData.userStoryIds = userStoryIds;
        requestData.userStoryBranches = userStoryBranches;
    }

    public static void populateChangeParameters(CreateExecutionRequestData requestData, List<User_Story_Metadata__c> userStoryMetadata) {
        // read all the User_Story_Metadata objects of all the user stories, make it a unique list
        // and save it into requestData.changes
        requestData.changes = new List<Change>();
        
        for (User_Story_Metadata__c record : userStoryMetadata) {
            requestData.changes.add(change(record));
        }
    }

    public static List<User_Story_Metadata__c> getUserStoryMetadata(List<Id> userStoryIds) {
        List<User_Story_Metadata__c> result = new UserStoryMetadataSelector().byUserStoryIds(new Set<Id>(userStoryIds));
        if (result.size() > 8000) {
            throw new ApplicationException(Label.Can_Not_Promote_More_Than_8000_Metadata);
        }
        return result;
    }

    public static void populateFileParameters(CreateExecutionRequestData requestData, Id parentId, String fileName) {
        // THIS is the File that the  Job will read if/when executed, avoiding the need of any Flow to gather the information
        String changesJson = Json.serialize(requestData.changes, true);
        requestData.changes = null; // remove the changes from the request

        Boolean executePromotion = requestData.executePromotion != null && requestData.executePromotion;
        Boolean executeDeployment = requestData.executeDeployment != null && requestData.executeDeployment;
        if (requestData.userStoryIds != null && !requestData.userStoryIds.isEmpty() && (executePromotion || executeDeployment)) {
            requestData.fileWithSelectedChanges = new Files().upsertFile(parentId, fileName, changesJson);
        }
    }

    public static Boolean isDeploymentJobExecutionCreated(CreateExecutionRequestData requestData) {
        requestData.deployment = new DeploymentsSelector().byPromotionId(requestData.promotionId);
        return requestData.deployment != null && (new JobExecutionsSelector().byDeploymentId(requestData.deployment.Id)) != null;
    }

    public static void updatePromotion(Id promotionId, String status) {
        updatePromotion(promotionId, status, false);
    }

    public static void updatePromotion(Id promotionId, String status, Boolean hasConflict) {
        List<SObject> records = new List<SObject>{ new Promotion__c(Id = promotionId, Status__c = status, Merge_Conflict__c = hasConflict) };
        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
        if (status == PromotionConstants.STATUS_COMPLETED_WITH_ERRORS) {
            new UpdatePromoteAndDeployOnUserStories(new Set<Id>{ promotionId }).execute();
        }
    }

    public static void getPromotionDetails(CreateExecutionRequestData requestData) {
        List<Promotion__c> promotions = new PromotionsSelector().promotionsDetailsForPromoteAndDeployActions(new Set<Id>{ requestData.promotionId });
        requestData.promotion = promotions.isEmpty() ? new Promotion__c() : promotions[0];
    }

    // TODO: Reduce parameter list
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<CreateExecution.Request> asRequests(
        RequestInfo requestInfo,
        List<JobStep__c> preSteps,
        List<JobStep__c> postSteps,
        List<AdditionalStep> additionalSteps
    ) {
        CreateExecutionRequestData requestData = requestInfo.data;
        Boolean runDeployJobExecution = requestData.executeDeployment ? requestData.executeDeployment : requestData.deploymentDryRun;

        CreateExecution.Request request = new CreateExecution.Request();
        request.templateName = requestInfo.templateName;
        request.pipelineId = new FindPipeline().fromObject(requestData.promotion);
        request.parentId = requestInfo.parentId;
        request.sourceId = requestData.promotion.Source_Environment__c;
        request.destinationId = requestData.promotion.Destination_Environment__c;
        request.callback = requestInfo.callbackClass;
        request.runAfterInstantiation = requestData.executePromotion != null ? requestData.executePromotion : runDeployJobExecution;
        request.preSteps = preSteps;
        request.postSteps = postSteps;
        request.additionalSteps = additionalSteps;

        requestData.promotion = null;
        requestData.deployment = null;

        request.dataJson = JSON.serializePretty(requestData, true);

        return new List<CreateExecution.Request>{ request };
    }

    public static List<CreateExecution.Request> asRequests(RequestInfo requestInfo) {
        return asRequests(requestInfo, null, null, null);
    }

    public static String destinationBranchName(Promotion__c promotion) {
        String pipelineId = new FindPipeline().fromObject(promotion);
        String branch = [
            SELECT Id, Branch__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :pipelineId AND Source_Environment__c = :promotion.Destination_Environment__c
            WITH SECURITY_ENFORCED
        ]
        ?.Branch__c;
        if (String.isBlank(branch)) {
            branch = [SELECT Id, Main_Branch__c FROM Deployment_Flow__c WHERE Id = :pipelineId WITH SECURITY_ENFORCED]?.Main_Branch__c;
        }
        return branch;
    }

    public class PromoteActionServiceException extends Exception {
    }

    // PRIVATE

    @SuppressWarnings('PMD.UnusedLocalVariable, PMD.ApexSOQLInjection')
    private static List<User_Story__c> getUserStoriesInOrder(Promotion__c promotion) {
        List<User_Story__c> result = new List<User_Story__c>();

        Id promotionId = promotion.Id;
        String orderBy = getUserStoriesOrder(promotion);
        // Note: False Positive. The validity of the order field is checked in the Promotion/Pipeline trigger on saving
        List<Promoted_User_Story__c> promotesUserStories = Database.query(
            'SELECT User_Story__r.Id, User_Story__r.Name FROM Promoted_User_Story__c WHERE Promoted_User_Story__c.Promotion__c = :promotionId WITH SECURITY_ENFORCED ORDER BY User_Story__r.' +
            orderBy
        );

        for (Promoted_User_Story__c promotedUserStory : promotesUserStories) {
            result.add(promotedUserStory.User_Story__r);
        }

        return result;
    }

    private static String getUserStoriesOrder(Promotion__c promotion) {
        String result = promotion.Order_By__c;

        if (String.isBlank(result)) {
            result = String.isNotBlank(promotion.Project__c)
                ? promotion.Project__r.Deployment_Flow__r.Order_by__c
                : promotion.Release__r.Project__r.Deployment_Flow__r.Order_by__c;
        }

        if (String.isBlank(result)) {
            result = 'Name ASC';
        }

        return result;
    }

    private static Change change(User_Story_Metadata__c record) {
        Change result = new Change();

        result.n = record.Metadata_API_Name__c;
        result.t = record.Type__c;
        result.m = record.ModuleDirectory__c;
        result.a = record.Action__c;
        result.c = record.Category__c;
        result.j = record.JsonInformation__c;
        result.u = record.User_Story__r.Name;

        return result;
    }

    // WRAPPER

    public with sharing class RequestInfo {
        CreateExecutionRequestData data;
        String templateName;
        Id parentId;
        String callbackClass;

        public RequestInfo(CreateExecutionRequestData data, String templateName, Id parentId) {
            this.data = data;
            this.templateName = templateName;
            this.parentId = parentId;
        }

        public RequestInfo callbackClass(String value) {
            this.callbackClass = value;
            return this;
        }
    }

    @SuppressWarnings('PMD.TooManyFields') // note: data contract variables. Cannot be changed.
    public with sharing class CreateExecutionRequestData {
        // Common variables for both Promote and Deploy action
        public Id promotionId;
        public Boolean deploymentDryRun;
        public Boolean executeDeployment;
        public String otherInformation;

        // Variables for Promote action
        public Id sourceEnvironmentId;
        public Boolean isBackPromotion;
        public Id projectId;
        public Boolean executePromotion;

        // Only used by the Job execution for both action
        public List<Change> changes; // list of all changes of each user story
        public Promotion__c promotion;
        public String destinationBranchName;
        public String promotionBranchName;
        public Id fileWithSelectedChanges;
        public List<Id> userStoryIds;
        public String gitTag;

        // Only used by the Job execution for Deploy Action
        public Id deploymentId;
        public Deployment__c deployment;

        // Only used by the Job execution for Promote Action
        public Id sourceCredentialId;
        public Id destinationCredentialId;
        public List<String> userStoryBranches = new List<String>();
        public List<Promotion__c> promotions;

        // Generic parameters for all actions
        public String actionCallback;
    }

    // NOTE: names are short to reduce memory/heap/transmission sizes
    public with sharing class Change {
        @InvocableVariable(required=true)
        public String n; // "name"

        @InvocableVariable
        public String t; // "type"

        @InvocableVariable
        public String m; // "module directory"

        @InvocableVariable(required=true)
        public String a; // "action" add, delete, retrieve-only, full pps, "deleteCascade"

        @InvocableVariable
        public String c; // optional, not used right now, "category" of this item: copadodx, vlocity, cpq, ...

        @InvocableVariable
        public String j; // "json additional information"... other values associated with this File

        @InvocableVariable
        public String u; // "user story name"... optional, user story name
    }
}