public with sharing class ExecuteUserStoryBundleServiceImpl {
    private static final String EXTENSION_USER_STORY_BUNDLE_LOGIC = 'UserStoryBundleLogic';
    private static final String EXTENSION_USER_STORY_BUNDLE_COMMIT_CALLBACK = 'UserStoryBundleCommitCallback';

    // PUBLIC

    public static Actions.ExecuteUserStoryBundleResult execute(Actions.ExecuteUserStoryBundleRequest request) {
        Actions.ExecuteUserStoryBundleResult result = new Actions.ExecuteUserStoryBundleResult();

        Map<Id, Bundled_Story__c> bundledStoriesById = new Map<Id, Bundled_Story__c>(
            [
                SELECT Id, User_Story__c, User_Story__r.Platform__c
                FROM Bundled_Story__c
                WHERE Package_Version__c = :request.packageVersionId
                WITH SECURITY_ENFORCED
            ]
        );

        List<Id> userStoryIds = new List<Id>();
        for (Bundled_Story__c bundledStory : bundledStoriesById.values()) {
            userStoryIds.add(bundledStory.User_Story__c);
        }

        // NOTE: taking platform from child stories, as bundleUserStory hasn't platform yet
        String platform = !bundledStoriesById.values().isEmpty() ? bundledStoriesById.values()[0].User_Story__r.Platform__c : null;
        String extensionFlowName = extensionFlowName(platform);

        if (String.isNotBlank(extensionFlowName)) {
            executeFlow(extensionFlowName, request);
            return result;
        }

        new UserStoryBundleValidator(userStoryIds).run();

        insertBundleStory(request.bundleUserStory);

        lockBundle(request.packageVersionId, request.bundleUserStory);

        cloneDeploymentSteps(userStoryIds, request.bundleUserStory.Id);

        unifyTests(userStoryIds, request.bundleUserStory.Id);

        excludeChildStoriesFromPipeline(bundledStoriesById);

        result.bundleUserStory = request.bundleUserStory;
        List<Actions.CommitChange> commitChanges = convertMetadataToCommitChange(userStoryIds);

        if (!commitChanges.isEmpty()) {
            Actions.CommitRequest commitRequest = new Actions.CommitRequest();
            commitRequest.userStoryId = request.bundleUserStory.Id;
            commitRequest.changes = commitChanges;
            commitRequest.actionCallback = getActionCallback(platform);
            result.commitResult = Actions.CommitService.execute(commitRequest);
        }
        return result;
    }

    // PRIVATE

    private static void insertBundleStory(User_Story__c parentStory) {
        parentStory.Is_Bundle__c = true;
        parentStory.RecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('Utility').getRecordTypeId();

        UserStories.bypassTrigger = true;
        DML.safeInsert(
            parentStory,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    User_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'ExecuteUserStoryBundleServiceImpl.insertBundleStory'
                }
            )
        );
        UserStories.bypassTrigger = false;
    }

    private static void lockBundle(Id bundleId, User_Story__c parentStory) {
        Artifact_Version__c packageVersion = [
            SELECT Id, User_Story__c, Status__c
            FROM Artifact_Version__c
            WHERE Id = :bundleId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        packageVersion.User_Story__c = parentStory.Id;
        packageVersion.Status__c = 'Locked';
        ArtifactVersionTriggerHandler.bypassTrigger = true;
        DML.safeUpdate(
            packageVersion,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    Artifact_Version__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'ExecuteUserStoryBundleServiceImpl.lockBundle'
                }
            )
        );
        ArtifactVersionTriggerHandler.bypassTrigger = false;
    }

    private static void excludeChildStoriesFromPipeline(Map<Id, Bundled_Story__c> bundledStoriesById) {
        List<User_Story__c> result = new List<User_Story__c>();
        for (Bundled_Story__c bundledStory : bundledStoriesById.values()) {
            User_Story__c userStory = new User_Story__c(
                Id = bundledStory.User_Story__c,
                Promote_Change__c = false,
                Stop_Indexing_Metadata__c = true,
                Exclude_From_CBM__c = true
            );

            result.add(userStory);
        }

        UserStories.bypassTrigger = true;
        DML.safeUpdate(
            result,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'ExecuteUserStoryBundleServiceImpl.excludeChildStoriesFromPipeline'
                }
            )
        );
        UserStories.bypassTrigger = false;
    }

    private static List<Actions.CommitChange> convertMetadataToCommitChange(List<Id> userStoryIds) {
        List<Actions.CommitChange> result = new List<Actions.CommitChange>();
        for (User_Story_Metadata__c metadata : [
            SELECT
                Id,
                Action__c,
                Category__c,
                ModuleDirectory__c,
                JsonInformation__c,
                Type__c,
                Metadata_API_Name__c,
                User_Story__c,
                Unique_ID__c,
                Name
            FROM User_Story_Metadata__c
            WHERE User_Story__c IN :userStoryIds
            WITH SECURITY_ENFORCED
        ]) {
            Actions.CommitChange change = new Actions.CommitChange();
            change.a = metadata.Action__c;
            change.c = metadata.Category__c;
            change.m = metadata.ModuleDirectory__c;
            change.j = metadata.JsonInformation__c;
            change.t = metadata.Type__c;
            change.n = metadata.Metadata_API_Name__c;
            result.add(change);
        }

        return result;
    }

    private static void cloneDeploymentSteps(List<Id> userStoryIds, Id bundleUserStoryId) {
        List<JobStep__c> deploymentTasksToInsert = new List<JobStep__c>();

        Integer orderCounter = 1;
        for (JobStep__c deploymentTask : [
            SELECT Id, Name, Type__c, Order__c, UserStory__c, ConfigJson__c, CustomType__c, ExecutionSequence__c, Result_Viewer_Component__c
            FROM JobStep__c
            WHERE UserStory__c IN :userStoryIds
            WITH SECURITY_ENFORCED
            ORDER BY UserStory__c ASC
        ]) {
            JobStep__c clonedDeploymentTask = deploymentTask.clone(false, true, true, true);
            clonedDeploymentTask.Order__c = orderCounter;
            clonedDeploymentTask.UserStory__c = bundleUserStoryId;
            deploymentTasksToInsert.add(clonedDeploymentTask);
            orderCounter++;
        }
        if (!deploymentTasksToInsert.isEmpty()) {
            DML.safeInsert(
                deploymentTasksToInsert,
                String.format(
                    Label.ErrorWhileInserting,
                    new List<String>{
                        JobStep__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'ExecuteUserStoryBundleServiceImpl.cloneDeploymentSteps'
                    }
                )
            );
        }
    }

    private static void unifyTests(List<Id> userStoryIds, Id bundleUserStoryId) {
        new UnifyTests(userStoryIds, bundleUserStoryId).execute();
    }

    private static void executeFlow(String flowName, Actions.ExecuteUserStoryBundleRequest request) {
        Map<String, Object> parameters = new Map<String, Object>{
            'packageVersionId' => request.packageVersionId,
            'bundleUserStory' => request.bundleUserStory
        };
        Flow.Interview.createInterview(namespace(flowName), name(flowName), parameters).start();
    }

    private static String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private static String name(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

    private static String extensionFlowName(String platform) {
        List<ExtensionKeyValueSetting__mdt> extensionSettings = new ExtensionKeyValueSettingsSelector()
            .byPlatformAndKey(platform, EXTENSION_USER_STORY_BUNDLE_LOGIC);
        return !extensionSettings.isEmpty() ? String.valueOf(extensionSettings[0].Value__c) : '';
    }

    private static String extensionCallback(String platform) {
        List<ExtensionKeyValueSetting__mdt> extensionSettings = new ExtensionKeyValueSettingsSelector()
            .byPlatformAndKey(platform, EXTENSION_USER_STORY_BUNDLE_COMMIT_CALLBACK);
        return !extensionSettings.isEmpty() ? String.valueOf(extensionSettings[0].Value__c) : '';
    }

    private static String getActionCallback(String platform) {
        String result = extensionCallback(platform);
        result = String.isBlank(result) ? UserStoryBundleCommitCallback.class.getName() : result;
        return result;
    }
}