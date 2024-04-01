public with sharing class ValidateScaConfiguration {
    // PUBLIC

    public void forCredential(Id credentialId) {
        List<Org__c> currentOrg = new List<Org__c>();
        List<Deployment_Flow_Step__c> curentPipeline = new List<Deployment_Flow_Step__c>();
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            currentOrg = [SELECT Environment__c FROM Org__c WHERE Id = :credentialId LIMIT 1];
        }

        if (currentOrg.isEmpty()) {
            throw new ApplicationException(Label.ORG_NOT_FOUND);
        }

        Id environmentId = currentOrg[0].Environment__c;
        if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            curentPipeline = [
                SELECT
                    Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                    Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName
                FROM Deployment_Flow_Step__c
                WHERE
                    (Source_Environment__c = :environmentId
                    OR Destination_Environment__c = :environmentId)
                    AND Deployment_Flow__r.Static_Code_Analysis_Settings__c != NULL
                LIMIT 1
            ];
        }

        if (curentPipeline.isEmpty()) {
            throw new ApplicationException(Label.SCA_SETTINGS_NOT_FOUND);
        }

        checkPmdRules(
            curentPipeline[0].Deployment_Flow__r.Static_Code_Analysis_Settings__c,
            curentPipeline[0].Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName
        );

        Set<Id> pipelineIds = getCodescanPipelineIdsRelatedTo(environmentId);
        List<Deployment_Flow__c> pipelines = new PipelineSelector().byIdsWithChilds(pipelineIds);
        for (Deployment_Flow__c pipeline : pipelines) {
            validateGitBranch(pipeline, environmentId);
        }
    }

    public void forUserStory(Id userStoryId) {
        List<User_Story__c> userStories = new List<User_Story__c>();
        if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            userStories = [
                SELECT
                    Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                    Project__r.Deployment_Flow__r.Git_Repository__c,
                    Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName,
                    Project__r.Deployment_Flow__c,
                    Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                    Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                    Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName,
                    Release__r.Project__r.Deployment_Flow__c,
                    Environment__c,
                    Name
                FROM User_Story__c
                WHERE Id = :userStoryId
                LIMIT 1
            ];
        }

        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.USER_STORY_NOT_FOUND);
        }

        String gitRepoId = getGitRepoId(userStories[0]);
        String scaSettingId = getScaSettingId(userStories[0]);
        String scaSettingRecordTypeDevName = getScaSettingRecordTypeDevName(userStories[0]);

        if (String.isBlank(scaSettingId)) {
            throw new ApplicationException(Label.SCA_SETTINGS_NOT_FOUND);
        }

        checkPmdRules(scaSettingId, scaSettingRecordTypeDevName);
    }

    // PRIVATE

    private Set<Id> getCodescanPipelineIdsRelatedTo(Id environmentId) {
        Set<Id> pipelineIds = new Set<Id>();
        List<Deployment_Flow_Step__c> pipelineConnections = new DeploymentFlowStepsSelector().byEnvironment(environmentId);
        for (Deployment_Flow_Step__c connection : pipelineConnections) {
            if (isCodescanSetIn(connection) && connection.Deployment_Flow__r.Git_Repository__c != null) {
                pipelineIds.add(connection.Deployment_Flow__c);
            }
        }

        return pipelineIds;
    }

    private Boolean isCodescanSetIn(Deployment_Flow_Step__c connection) {
        Id codeScanRecordType = (Id) Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByName().get('CodeScan').getRecordTypeId();

        return (connection.Deployment_Flow__r.Static_Code_Analysis_Settings__c != null &&
        connection.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordTypeId == codeScanRecordType);
    }

    private void validateGitBranch(Deployment_Flow__c pipeline, Id environmentId) {
        Boolean isSourceEnvironment = false;
        for (Deployment_Flow_Step__c connection : pipeline.Deployment_Flow_Steps__r) {
            if (environmentId == connection.Source_Environment__c) {
                isSourceEnvironment = true;
                validateConnectionBranch(connection);
            }
        }

        if (!isSourceEnvironment) {
            validatePipelineBranch(pipeline);
        }
    }

    private void validatePipelineBranch(Deployment_Flow__c pipeline) {
        if (String.isBlank(pipeline.Main_Branch__c)) {
            throw new ApplicationException(String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE, new List<String>{ pipeline.Id }));
        }
    }

    private void validateConnectionBranch(Deployment_Flow_Step__c connection) {
        if (String.isBlank(connection.Branch__c)) {
            throw new ApplicationException(String.format(Label.SCA_MISSING_GIT_BRANCH_PIPELINE_CONNECTION, new List<String>{ connection.Id }));
        }
    }

    private static void checkPmdRules(String scaSettingId, String scaSettingRecordTypeDevName) {
        if (!Schema.SObjectType.Static_Code_Analysis_Rule__c.isQueryable() && !Schema.SObjectType.Static_Code_Analysis_Rule__c.isAccessible()) {
            throw new ApplicationException(Label.SCA_RULES_NOT_FOUND);
        }
        List<Static_Code_Analysis_Rule__c> rules = [
            SELECT Id
            FROM Static_Code_Analysis_Rule__c
            WHERE Static_Code_Analysis_Settings__c = :scaSettingId
        ];
        if (rules.isEmpty() && scaSettingRecordTypeDevName != 'CodeScan') {
            throw new ApplicationException(Label.SCA_RULES_NOT_FOUND);
        }
    }

    private static String getGitRepoId(User_Story__c userStory) {
        return String.isNotBlank(userStory.Project__r.Deployment_Flow__r.Git_Repository__c)
            ? userStory.Project__r.Deployment_Flow__r.Git_Repository__c
            : userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
    }

    private static String getScaSettingId(User_Story__c userStory) {
        return userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c != null
            ? userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c
            : userStory.Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c;
    }

    private static String getScaSettingRecordTypeDevName(User_Story__c userStory) {
        return String.isNotBlank(userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName)
            ? userStory.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName
            : userStory.Release__r.Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__r.RecordType.DeveloperName;
    }

    private class GitWrapper {
        List<GitMetaData> att { get; set; }
    }

    private class MetaData {
        public String n { get; set; }
        public Boolean s { get; set; }
        public String d { get; set; }
        public String b { get; set; }
        public String cd { get; set; }
        public String cb { get; set; }
        public String t { get; set; }
    }

    private class GitMetaData {
        public String t { get; set; }
        public String n { get; set; }
        public String cmm { get; set; }
    }
}