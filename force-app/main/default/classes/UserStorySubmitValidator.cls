public with sharing class UserStorySubmitValidator {
    private User_Story__c userStory;
    private List<Deployment_Flow_Step__c> pipelineConnections;

    // CONSTRUCTOR

    public UserStorySubmitValidator(User_Story__c userStory) {
        this.userStory = userStory;
    }

    public UserStorySubmitValidator pipelineConnections(List<Deployment_Flow_Step__c> pipelineConnections) {
        this.pipelineConnections = pipelineConnections;
        return this;
    }

    // PUBLIC

    public List<String> execute() {
        this.pipelineConnections = this.pipelineConnections == null ? getPipelineConnections(this.userStory) : this.pipelineConnections;

        List<String> result = new List<String>();

        result.addAll(checkPermissions());
        if (!result.isEmpty()) {
            return result;
        }

        result.addAll(checkMandatoryFields());
        if (!result.isEmpty()) {
            return result;
        }

        result.addAll(checkMetadataOrDeploymentSteps());
        result.addAll(checkPipelineConnections());
        result.addAll(checkUserStoryExcluded());

        return result;
    }

    // PRIVATE

    private List<String> checkMandatoryFields() {
        List<String> result = new List<String>();
        if ((String.isBlank(userStory.Project__c) && String.isBlank(userStory.Release__c)) || String.isBlank(userStory.Environment__c)) {
            result.add(Label.Mandatory_Fields_To_Submit);
        }
        return result;
    }

    // TODO : Convert to permission sets instead of individual check in future
    private List<String> checkPermissions() {
        List<String> result = new List<String>();

        List<String> objectsWithoutPermissions = new List<String>();
        objectsWithoutPermissions.addAll(isUpdateable(Schema.SObjectType.User_Story__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.Git_Commit__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.User_Story_Metadata__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.Promotion__c));
        objectsWithoutPermissions.addAll(isReadable(Schema.SObjectType.Deployment_Flow__c));
        objectsWithoutPermissions.addAll(isReadable(Schema.SObjectType.Deployment_Flow_Step__c));
        objectsWithoutPermissions.addAll(isReadable(Schema.SObjectType.Pipeline_Action__c));
        objectsWithoutPermissions.addAll(isReadable(Schema.SObjectType.JobTemplate__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.JobStep__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.JobExecution__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.Result__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.Deployment__c));
        objectsWithoutPermissions.addAll(isCreatableAndUpdateable(Schema.SObjectType.Deployment_Task__c));
        if (!objectsWithoutPermissions.isEmpty()) {
            result.add(
                String.format(Label.Submit_User_Story_Validate_Object_Permissions, new List<String>{ String.join(objectsWithoutPermissions, ', ') })
            );
        }

        List<String> fieldsWithoutPermissions = new List<String>();
        fieldsWithoutPermissions.addAll(isUpdateable(Schema.sObjectType.User_Story__c.fields.Promote_Change__c));
        fieldsWithoutPermissions.addAll(isUpdateable(Schema.sObjectType.User_Story__c.fields.Promote_and_Deploy__c));
        if (!fieldsWithoutPermissions.isEmpty()) {
            result.add(
                String.format(Label.Submit_User_Story_Validate_Field_Permissions, new List<String>{ String.join(fieldsWithoutPermissions, ', ') })
            );
        }

        return result;
    }

    private List<String> isCreatableAndUpdateable(Schema.DescribeSObjectResult describeSObject) {
        List<String> result = new List<String>();
        if (!describeSObject.isCreateable() || !describeSObject.isUpdateable()) {
            result.add(describeSObject.Label + ' (Create/Update)');
        }
        return result;
    }

    private List<String> isReadable(Schema.DescribeSObjectResult describeSObject) {
        List<String> result = new List<String>();
        if (!describeSObject.isAccessible()) {
            result.add(describeSObject.Label + ' (Read)');
        }
        return result;
    }

    private List<String> isUpdateable(Schema.DescribeSObjectResult describeSObject) {
        List<String> result = new List<String>();
        if (!describeSObject.isUpdateable()) {
            result.add(describeSObject.Label + ' (Update)');
        }
        return result;
    }

    private List<String> isUpdateable(Schema.DescribeFieldResult describeField) {
        List<String> result = new List<String>();
        if (!describeField.isUpdateable()) {
            result.add(describeField.getLabel());
        }
        return result;
    }

    private List<String> checkMetadataOrDeploymentSteps() {
        List<String> result = new List<String>();

        Boolean hasSomethingToPromote = new ValidateUserStoryHasSomethingToPromote(userStory).execute();
        if (!hasSomethingToPromote) {
            result.add(Label.Can_Not_Promote_If_Either_No_Deployment_Steps_or_Metadata_Commits);
        }

        return result;
    }

    private List<String> checkPipelineConnections() {
        List<String> result = new List<String>();

        if (pipelineConnections.isEmpty()) {
            result.add(Label.Submit_User_Story_Validate_Pipeline_And_Environment);
            return result;
        }

        List<Deployment_Flow_Step__c> pipelineConnectionsFromSource = new List<Deployment_Flow_Step__c>();
        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            if (pipelineConnection.Source_Environment__c == userStory.Environment__c) {
                pipelineConnectionsFromSource.add(pipelineConnection);
            }
        }
        if (pipelineConnectionsFromSource.isEmpty()) {
            result.add(Label.Submit_User_Story_Validate_Last_Environment);
        }

        return result;
    }

    private List<String> checkUserStoryExcluded() {
        List<String> result = new List<String>();
        if (userStory.Exclude_From_CBM__c) {
            result.add(Label.Submit_User_Story_Validate_Excluded_From_Pipeline);
        }
        return result;
    }

    private static List<Deployment_Flow_Step__c> getPipelineConnections(User_Story__c userStory) {
        List<Deployment_Flow_Step__c> result = new List<Deployment_Flow_Step__c>();
        Id pipelineId = new FindPipeline().fromObject(userStory);

        if (pipelineId != null && userStory.Environment__c != null) {
            result = [
                SELECT Id, Source_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name
                FROM Deployment_Flow_Step__c
                WHERE
                    (Source_Environment__c = :userStory.Environment__c
                    OR Destination_Environment__c = :userStory.Environment__c)
                    AND Deployment_Flow__c = :pipelineId
                WITH USER_MODE
            ];
        }

        return result;
    }
}