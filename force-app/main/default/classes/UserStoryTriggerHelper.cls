@SuppressWarnings('PMD')
public with sharing class UserStoryTriggerHelper {
    private static Map<Id, Id> pipelineIdsByUserStoryIds;
    private static Map<Id, Deployment_Flow_Step__c> pipelineConnectionsBySourceEnvironmentIds;
    private static Map<Id, Sprint__c> mapSprint;
    private static Map<Id, Org__c> orgMap;
    private static Map<Id, User_Story__c> usUpdateMap = new Map<Id, User_Story__c>();
    private static Boolean usFlagToStopRecursiveUpdate = false;
    private static Map<Id, Decimal> maxUserStoriesOrderBySprint = new Map<Id, Decimal>();
    private static Map<Id, Project__c> projectsById;
    private static Map<Id, Deployment_Flow__c> deploymentFlowsById;
    private static Set<Id> metadataIdsToEnable = new Set<Id>();
    private static Set<Id> userStoryIdsToEnableMC = new Set<Id>();
    private static Set<Id> metadataIdsToDisable = new Set<Id>();
    private static Set<Id> userStoryIdsToDisableMC = new Set<Id>();
    private static Set<Promotion__c> promotions = new Set<Promotion__c>();
    private static Map<Id, Decimal> lastOrderNumberMap = new Map<Id, Decimal>();
    private static Map<String, List<User_Story__c>> storiesByPromotion = new Map<String, List<User_Story__c>>();
    private static Set<Id> sourceEnvironmentIds;
    private static Map<Id, User_Story__c> userStoryBySprintIdsForPlannedVelocity = new Map<Id, User_Story__c>();
    private static Map<Id, User_Story__c> userStoryBySprintIdsForActualVelocity = new Map<Id, User_Story__c>();
    private static Map<Id, Id> releaseIdByUserStoryId = new Map<Id, Id>();
    private static Map<Id, Id> teamIdByUserStoryId = new Map<Id, Id>();
    public static List<User_Story__c> promoteAndDeployedStories;
    public static List<User_Story__c> readyToSubmitUSs;
    public static Map<Id, Environment__c> environmentMap;
    public static Map<Id, Release__c> releaseMap;
    public static Set<Promoted_User_Story__c> promotedUserStoriesToUpdateAsOutdated = new Set<Promoted_User_Story__c>();
    private static Set<Id> completedUSIdsForDependencies = new Set<Id>();
    private static Set<Id> deletedUSIdsForDependencies = new Set<Id>();
    private static final String COMPLETED = 'Completed';
    private static final String ACTUAL_VELOCITY_STATUSES_MDT = 'Actual_Velocity_Statuses';
    private static Set<String> actualVelocityStatus = getCustomMetadataValues(ACTUAL_VELOCITY_STATUSES_MDT, COMPLETED);
    private static final String US_DEPENDENCY_COMPLETED_STATUSES_MDT = 'US_Dependency_Completed_Statuses';
    private static Set<String> dependencyCompletedStatus = getCustomMetadataValues(US_DEPENDENCY_COMPLETED_STATUSES_MDT, COMPLETED);
    private static final Set<String> USER_STORY_DEPENDENCY_QUERY_FIELDS = new Set<String>{
        'Id',
        'Dependent_User_Story__c',
        'Child_User_Story_Release__c',
        'Dependent_Team__c',
        'Provider_User_Story__c',
        'Release__c',
        'Provider_Team__c',
        'Dependency_Status__c'
    };
    private static final String USER_STORY_DEPENDENCY_QUERY = 'SELECT {0} FROM Team_Dependency__c WHERE {1}';
    private static Map<Id, User_Story__c> newUpdatedUsIds = new Map<Id, User_Story__c>();
    private static Map<Id, User_Story__c> oldUpdatedUsIds = new Map<Id, User_Story__c>();
    private static Map<Id, Id> initialSourceEnvironmentByUserStoryId = new Map<Id, Id>();
    private static Map<Id, List<Promoted_User_Story__c>> promotedUserStoriesByUserStoryId {
        get {
            if (promotedUserStoriesByUserStoryId == null) {
                promotedUserStoriesByUserStoryId = new Map<Id, List<Promoted_User_Story__c>>();
                for (Promoted_User_Story__c promotedUserStory : [
                    SELECT User_Story__c, Promotion__c, Promotion__r.Status__c, Promotion__r.Source_Environment__c
                    FROM Promoted_User_Story__c
                    WHERE Status__c != :PromotionConstants.STATUS_OUTDATED AND User_Story__c IN :newUpdatedUsIds.keySet()
                    ORDER BY CreatedDate ASC
                ]) {
                    if (!promotedUserStoriesByUserStoryId.containsKey(promotedUserStory.User_Story__c)) {
                        initialSourceEnvironmentByUserStoryId.put(
                            promotedUserStory.User_Story__c,
                            promotedUserStory.Promotion__r.Source_Environment__c
                        );
                        promotedUserStoriesByUserStoryId.put(promotedUserStory.User_Story__c, new List<Promoted_User_Story__c>());
                    }
                    promotedUserStoriesByUserStoryId.get(promotedUserStory.User_Story__c).add(promotedUserStory);
                }
            }
            return promotedUserStoriesByUserStoryId;
        }
        set;
    }

    public static void prepareMaps() {
        if (Trigger.isDelete)
            return;

        Set<Id> setSprintIds = new Set<Id>();
        Set<Id> oids = new Set<Id>();
        Set<Id> envids = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> releaseIds = new Set<Id>();
        promoteAndDeployedStories = new List<User_Story__c>();
        readyToSubmitUSs = new List<User_Story__c>();

        for (SObject so : Trigger.new) {
            User_Story__c userStoryRecord = (User_Story__c) so;
            setSprintIds.add(userStoryRecord.Sprint__c);
            oids.add(userStoryRecord.org_credential__c);
            if (userStoryRecord.Environment__c != null) {
                envIds.add(userStoryRecord.Environment__c);
            }
            if (userStoryRecord.Project__c != null) {
                projectIds.add(userStoryRecord.Project__c);
            }
            if (userStoryRecord.Release__c != null) {
                releaseIds.add(userStoryRecord.Release__c);
            }
        }

        orgMap = new Map<Id, Org__c>([SELECT Id, OwnerId, Environment__c FROM Org__c WHERE Id IN :oids]);
        for (Org__c org : orgMap.values()) {
            envIds.add(org.Environment__c);
        }
        if (!envIds.isEmpty()) {
            environmentMap = new Map<Id, Environment__c>([SELECT Id, Name, Minimum_Apex_Test_Coverage__c FROM Environment__c WHERE Id IN :envIds]);
        }
        if (!releaseIds.isEmpty()) {
            releaseMap = new Map<Id, Release__c>(
                [SELECT Id, Base_Branch__c, Project__c, Project__r.Deployment_Flow__c FROM Release__c WHERE Id IN :releaseIds]
            );
        }
        if (!setSprintIds.isEmpty()) {
            mapSprint = new Map<Id, Sprint__c>([SELECT Id, Project__c FROM Sprint__c WHERE Id IN :setSprintIds]);
        }
        for (AggregateResult maxUserStoryOrderGroupBySprint : [
            SELECT MAX(Order__c) order, Sprint__c sprint
            FROM User_Story__c
            WHERE Sprint__c IN :setSprintIds
            GROUP BY Sprint__c
        ]) {
            maxUserStoriesOrderBySprint.put((Id) maxUserStoryOrderGroupBySprint.get('sprint'), (Decimal) maxUserStoryOrderGroupBySprint.get('order'));
        }
        if (Trigger.isUpdate) {
            if (!projectIds.isEmpty()) {
                projectsById = new Map<Id, Project__c>([SELECT Deployment_Flow__c FROM Project__c WHERE Id IN :projectIds]);
            }
            pipelineIdsByUserStoryIds = new Map<Id, Id>();

            for (SObject so : Trigger.new) {
                User_Story__c userStoryRecord = (User_Story__c) so;

                if (releaseMap != null) {
                    for (Release__c release : releaseMap.values()) {
                        if (release.Project__c != null && release.Project__r.Deployment_Flow__c != null) {
                            pipelineIdsByUserStoryIds.put(userStoryRecord.Id, release.Project__r.Deployment_Flow__c);
                        }
                    }
                }

                if (projectsById != null) {
                    for (Project__c project : projectsById.values()) {
                        if (project.Deployment_Flow__c != null && project.Id == userStoryRecord.Project__c) {
                            pipelineIdsByUserStoryIds.put(userStoryRecord.Id, project.Deployment_Flow__c);
                        }
                    }
                }
            }

            deploymentFlowsById = new Map<Id, Deployment_Flow__c>(
                [
                    SELECT
                        Id,
                        Platform__c,
                        (
                            SELECT
                                Source_Environment__c,
                                Destination_Environment__c,
                                Destination_Environment__r.Name,
                                Destination_Environment__r.Run_all_tests__c
                            FROM Deployment_Flow_Steps__r
                        )
                    FROM Deployment_Flow__c
                    WHERE Id IN :pipelineIdsByUserStoryIds.values()
                ]
            );
            pipelineConnectionsBySourceEnvironmentIds = new Map<Id, Deployment_Flow_Step__c>();
            for (Deployment_Flow__c pipelineRecord : deploymentFlowsById.values()) {
                for (Deployment_Flow_Step__c pipelineConnectionRecord : pipelineRecord.Deployment_Flow_Steps__r) {
                    pipelineConnectionsBySourceEnvironmentIds.put(pipelineConnectionRecord.Source_Environment__c, pipelineConnectionRecord);
                }
            }

            for (SObject so : Trigger.old) {
                User_Story__c old = (User_Story__c) so;
                User_Story__c usNew = (User_Story__c) Trigger.newMap.get(so.Id);
                if (old.Sprint__c == null) {
                    if (usNew.Sprint__c != null && usNew.Project__c == null) {
                        usNew.Project__c = mapSprint.get(usNew.Sprint__c).Project__c;
                    }
                }
            }
        }
    }

    public static void setProject(User_Story__c usNew) {
        if (usNew.Sprint__c != null && usNew.Project__c == null) {
            usNew.Project__c = mapSprint.get(usNew.Sprint__c).Project__c;
        }
    }

    public static void setEnvironment(User_Story__c userStoryRecord) {
        if (userStoryRecord.Environment__c == null && userStoryRecord.Org_Credential__c != null) {
            userStoryRecord.Environment__c = orgMap.get(userStoryRecord.Org_Credential__c).Environment__c;
        }
        if (userStoryRecord.Environment__c != null && environmentMap.get(userStoryRecord.Environment__c) != null) {
            Environment__c env = environmentMap.get(userStoryRecord.Environment__c);
            if (userStoryRecord.Minimum_Apex_Code_Coverage__c < env.Minimum_Apex_Test_Coverage__c) {
                userStoryRecord.Minimum_Apex_Code_Coverage__c = env.Minimum_Apex_Test_Coverage__c;
            }
        }
    }

    public static void checkSprints(User_Story__c oldUserStoryRecord, User_Story__c userStoryRecord) {
        if (
            oldUserStoryRecord != null &&
            (oldUserStoryRecord.Status__c == 'Backlog' ||
            oldUserStoryRecord.Status__c == 'Backburner') &&
            userStoryRecord.Status__c == oldUserStoryRecord.Status__c &&
            oldUserStoryRecord.Sprint__c == null &&
            userStoryRecord.Sprint__c != null
        ) {
            userStoryRecord.Status__c = 'Approved';
        } else if ((userStoryRecord.Status__c == 'Backlog' || userStoryRecord.Status__c == 'Backburner') && userStoryRecord.Sprint__c != null) {
            userStoryRecord.Sprint__c = null;
        }
    }

    public static void setOrderBeforeUpdate(User_Story__c oldUserStoryRecord, User_Story__c userStoryRecord) {
        if (
            userStoryRecord.Sprint__c != null &&
            (null == oldUserStoryRecord ||
            (userStoryRecord.Sprint__c != oldUserStoryRecord.Sprint__c) ||
            (userStoryRecord.Sprint__c == oldUserStoryRecord.Sprint__c &&
            null == userStoryRecord.Order__c &&
            null != oldUserStoryRecord.Order__c))
        ) {
            // Order will be updated based on sprint on user story create and update action
            // OR
            // Sprint is changed so we need to update order based on new sprint. We will assign the last order number.
            if (!lastOrderNumberMap.containsKey(userStoryRecord.Sprint__c) && maxUserStoriesOrderBySprint.containsKey(userStoryRecord.Sprint__c)) {
                Decimal maxNumber = maxUserStoriesOrderBySprint.get(userStoryRecord.Sprint__c) != null
                    ? maxUserStoriesOrderBySprint.get(userStoryRecord.Sprint__c) +
                      ((oldUserStoryRecord == null || (oldUserStoryRecord.Order__c != maxUserStoriesOrderBySprint.get(userStoryRecord.Sprint__c)))
                          ? 1
                          : 0)
                    : 1;
                lastOrderNumberMap.put(userStoryRecord.Sprint__c, maxNumber);
            }
            userStoryRecord.Order__c = lastOrderNumberMap.containsKey(userStoryRecord.Sprint__c)
                ? lastOrderNumberMap.get(userStoryRecord.Sprint__c)
                : 1;
            Decimal currentOrderNumber = lastOrderNumberMap.containsKey(userStoryRecord.Sprint__c)
                ? lastOrderNumberMap.get(userStoryRecord.Sprint__c) + 1
                : 1;
            lastOrderNumberMap.put(userStoryRecord.Sprint__c, currentOrderNumber);
        } else if (null == userStoryRecord.Sprint__c) {
            // Sprint lookup is removed so Order is going to be null to be updated later.
            userStoryRecord.Order__c = null;
        }
    }

    public static void getSprintVelocity(SObject oldSo, SObject so) {
        getSprintsForPlannedVelocity((User_Story__c) oldSo, (User_Story__c) so);
        getSprintsForActualVelocity((User_Story__c) oldSo, (User_Story__c) so);
    }

    public static void getReleaseAndTeamForUserStory(SObject oldSo, SObject so) {
        getUserStoriesWithRelease((User_Story__c) oldSo, (User_Story__c) so);
        getUserStoriesWithdTeam((User_Story__c) oldSo, (User_Story__c) so);
    }

    public static void getCompletedUSforDependency(SObject oldSo, SObject so) {
        prepareCompletedUserStories((User_Story__c) oldSo, (User_Story__c) so);
    }

    public static void getDeletedUSforDependencyDelete(SObject so) {
        User_Story__c deletedUserStoryRecord = (User_Story__c) so;
        deletedUSIdsForDependencies.add(deletedUserStoryRecord.Id);
    }

    public static void updateSprintVelocity() {
        updateSprintsPlannedVelocity();
        updateSprintsActualVelocity();
    }

    public static void updateUserStoryDependencies() {
        List<Team_Dependency__c> userStoriesDependencies = getUserStoriesDependenciesRecords();
        processUserStoriesDependencyRecords(userStoriesDependencies);
    }

    public static void cascadeDeleteUSDependencies() {
        List<Team_Dependency__c> usDependenciesToDelete = getUserStoriesDependencies(deletedUSIdsForDependencies, deletedUSIdsForDependencies, 'OR');
        deleteUserStoriesDependencies(usDependenciesToDelete);
    }

    private static List<Team_Dependency__c> getUserStoriesDependenciesRecords() {
        Set<Id> dependentStoriesIds = new Set<Id>();
        Set<Id> providerStoriesIds = new Set<Id>();

        dependentStoriesIds.addAll(addUSIdsForReleaseChanges());
        dependentStoriesIds.addAll(addUSIdsForTeamChanges());
        providerStoriesIds.addAll(dependentStoriesIds);
        providerStoriesIds.addAll(addUSIdsForStatusCompleted());

        return getUserStoriesDependencies(dependentStoriesIds, providerStoriesIds, 'OR');
    }

    private static Set<Id> addUSIdsForReleaseChanges() {
        Set<Id> result = new Set<Id>();
        Boolean hasReleaseChanges = releaseIdByUserStoryId != null && releaseIdByUserStoryId.size() > 0;
        if (hasReleaseChanges) {
            result = releaseIdByUserStoryId.keySet();
        }
        return result;
    }

    private static Set<Id> addUSIdsForTeamChanges() {
        Set<Id> result = new Set<Id>();
        Boolean hasTeamChanges = teamIdByUserStoryId != null && teamIdByUserStoryId.size() > 0;
        if (hasTeamChanges) {
            result = teamIdByUserStoryId.keySet();
        }
        return result;
    }

    private static Set<Id> addUSIdsForStatusCompleted() {
        Set<Id> result = new Set<Id>();
        Boolean hasUserStoriesCompleted = completedUSIdsForDependencies != null && completedUSIdsForDependencies.size() > 0;
        if (hasUserStoriesCompleted) {
            result = completedUSIdsForDependencies;
        }
        return result;
    }

    private static List<Team_Dependency__c> getUserStoriesDependencies(
        Set<Id> dependentStoriesIds,
        Set<Id> providerStoriesIds,
        String logicalOperator
    ) {
        Boolean hasNodependentStoriesIds = dependentStoriesIds == null || dependentStoriesIds.size() == 0;
        Boolean hasNoproviderStoriesIds = providerStoriesIds == null || providerStoriesIds.size() == 0;
        if (hasNodependentStoriesIds && hasNoproviderStoriesIds) {
            return new List<Team_Dependency__c>();
        }
        String query = String.format(
            USER_STORY_DEPENDENCY_QUERY,
            getUSDependencyQueryParameters(dependentStoriesIds, providerStoriesIds, logicalOperator)
        );
        return Database.query(query);
    }

    private static List<Object> getUSDependencyQueryParameters(Set<Id> dependentStoriesIds, Set<Id> providerStoriesIds, String logicalOperator) {
        String whereClause = '';
        if (dependentStoriesIds != null && !dependentStoriesIds.isEmpty()) {
            whereClause = 'Dependent_User_Story__c IN : dependentStoriesIds';
        }
        if (String.isNotBlank(whereClause)) {
            logicalOperator = String.isNotBlank(logicalOperator) ? logicalOperator : 'AND';
            whereClause += ' ' + logicalOperator + ' ';
        }
        if (providerStoriesIds != null && !providerStoriesIds.isEmpty()) {
            whereClause += 'Provider_User_Story__c IN : providerStoriesIds';
        }
        return new List<Object>{ getUSDependencySelectFields(), whereClause };
    }

    private static String getUSDependencySelectFields() {
        return String.join(new List<String>(USER_STORY_DEPENDENCY_QUERY_FIELDS), ', ');
    }

    private static void processUserStoriesDependencyRecords(List<Team_Dependency__c> userStoriesDependencies) {
        List<Team_Dependency__c> updateUserStoryDependecies = new List<Team_Dependency__c>();

        for (Team_Dependency__c userStorydependency : userStoriesDependencies) {
            updateParentReleaseAndTeam(userStorydependency);
            updateChildReleaseAndTeam(userStorydependency);
            updateDependencyStatusToCompleted(userStorydependency);
            updateUserStoryDependecies.add(userStorydependency);
        }
        Utilities.Secure_DML(
            new List<Team_Dependency__c>(updateUserStoryDependecies),
            Utilities.DML_Action.UPD,
            Schema.SObjectType.Team_Dependency__c
        );
    }

    private static void deleteUserStoriesDependencies(List<Team_Dependency__c> usDependenciesToDelete) {
        Utilities.Secure_DML(new List<Team_Dependency__c>(usDependenciesToDelete), Utilities.DML_Action.DEL, Schema.SObjectType.Team_Dependency__c);
    }

    private static void updateParentReleaseAndTeam(Team_Dependency__c userStorydependency) {
        if (releaseIdByUserStoryId.containsKey(userStorydependency.Provider_User_Story__c)) {
            userStorydependency.Release__c = releaseIdByUserStoryId.get(userStorydependency.Provider_User_Story__c);
        }
        if (teamIdByUserStoryId.containsKey(userStorydependency.Provider_User_Story__c)) {
            userStorydependency.Provider_Team__c = teamIdByUserStoryId.get(userStorydependency.Provider_User_Story__c);
        }
    }

    private static void updateChildReleaseAndTeam(Team_Dependency__c userStorydependency) {
        if (releaseIdByUserStoryId.containsKey(userStorydependency.Dependent_User_Story__c)) {
            userStorydependency.Child_User_Story_Release__c = releaseIdByUserStoryId.get(userStorydependency.Dependent_User_Story__c);
        }
        if (teamIdByUserStoryId.containsKey(userStorydependency.Dependent_User_Story__c)) {
            userStorydependency.Dependent_Team__c = teamIdByUserStoryId.get(userStorydependency.Dependent_User_Story__c);
        }
    }

    private static void updateDependencyStatusToCompleted(Team_Dependency__c userStorydependency) {
        if (completedUSIdsForDependencies.contains(userStorydependency.Provider_User_Story__c)) {
            userStorydependency.Dependency_Status__c = COMPLETED;
        }
    }

    public static void setChildPromotedUserStoriesAsOutdated(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (oldUserStoryRecord.Environment__c != newUserStoryRecord.Environment__c) {
            newUpdatedUsIds.put(newUserStoryRecord.Id, newUserStoryRecord);
            oldUpdatedUsIds.put(oldUserStoryRecord.Id, oldUserStoryRecord);
        }
    }

    private static void isNewEnvironmentLowerInPipeline(
        List<Deployment_Flow_Step__c> pipelineConnections,
        Id previousEnvironmentId,
        Id newEnvironmentId
    ) {
        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            if (pipelineConnection.Source_Environment__c == newEnvironmentId) {
                sourceEnvironmentIds.add(pipelineConnection.Source_Environment__c);
                if (pipelineConnection.Destination_Environment__c != previousEnvironmentId) {
                    isNewEnvironmentLowerInPipeline(pipelineConnections, previousEnvironmentId, pipelineConnection.Destination_Environment__c);
                }
            }
        }
    }

    public static void addUserStoryToSubmitQueue(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (platformUserStory(newUserStoryRecord) && readyToPromoteUserStory(oldUserStoryRecord, newUserStoryRecord)) {
            readyToSubmitUSs.add(newUserStoryRecord);
        }
    }

    private static Boolean platformUserStory(User_Story__c userStory) {
        return String.isNotBlank(userStory.Platform__c) && userStory.Platform__c != 'Salesforce';
    }

    private static Boolean readyToPromoteUserStory(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        return !newUserStoryRecord.Promote_and_Deploy__c && !oldUserStoryRecord.Promote_Change__c && newUserStoryRecord.Promote_Change__c;
    }

    public static void submitUserStories() {
        if (readyToSubmitUSs.isEmpty()) {
            return;
        }
        for (User_Story__c userStory : readyToSubmitUSs) {
            Actions.SubmitUserStoryRequest request = new Actions.SubmitUserStoryRequest();
            request.userStoryId = userStory.Id;
            try {
                Actions.SubmitUserStoryService.submit(request);
            } catch (Exception e) {
                userStory.addError(e.getMessage());
            }
        }
    }

    public static void addUserStoryToPromoteDeployQueue(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (!oldUserStoryRecord.Promote_and_Deploy__c && newUserStoryRecord.Promote_and_Deploy__c) {
            promoteAndDeployedStories.add(newUserStoryRecord);
        }
    }

    public static void checkIndexMetadataChanged(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (!oldUserStoryRecord.Stop_Indexing_Metadata__c && newUserStoryRecord.Stop_Indexing_Metadata__c) {
            if (platformUserStory(newUserStoryRecord)) {
                userStoryIdsToDisableMC.add(newUserStoryRecord.Id);
            } else {
                metadataIdsToDisable.add(newUserStoryRecord.Id);
            }
        } else if (oldUserStoryRecord.Stop_Indexing_Metadata__c && !newUserStoryRecord.Stop_Indexing_Metadata__c) {
            if (platformUserStory(newUserStoryRecord)) {
                userStoryIdsToEnableMC.add(newUserStoryRecord.Id);
            } else {
                metadataIdsToEnable.add(newUserStoryRecord.Id);
            }
        }
    }

    public static void promoteAndDeployUserStories() {
        List<User_Story__c> classicUserStories = new List<User_Story__c>();
        List<User_Story__c> multiCloudUserStories = new List<User_Story__c>();
        for (User_Story__c userStoryRecord : promoteAndDeployedStories) {
            if (userStoryRecord.Platform__c == 'Salesforce' || userStoryRecord.Platform__c == null) {
                classicUserStories.add(userStoryRecord);
            } else {
                multiCloudUserStories.add(userStoryRecord);
            }
        }

        promoteClassic(classicUserStories);
        promoteMultiCloud(multiCloudUserStories);
    }

    private static void promoteMultiCloud(List<User_Story__c> userStories) {
        if (userStories.isEmpty())
            return;

        try {
            Set<Id> userStoryIds = new Set<Id>();
            Id projectId = userStories[0].Project__c;
            Id environmentId = userStories[0].Environment__c;

            for (User_Story__c userStory : userStories) {
                if (projectId != userStory.Project__c || environmentId != userStory.Environment__c) {
                    userStory.addError(Label.ERROR_PROMOTION_DIFFERENT_PROJECT_OR_ENVIRONMENT);
                }
                userStoryIds.add(userStory.Id);
            }

            PromoteAction.Request request = new PromoteAction.Request();
            request.executePromotion = true;
            request.executeDeployment = true;
            request.deploymentDryRun = false;
            request.sourceEnvironmentId = environmentId;
            request.userStoryIds = new List<Id>(userStoryIds);
            PromoteAction.promote(new List<PromoteAction.Request>{ request });
        } catch (Exception e) {
            userStories[0].addError(returnValidationError(e.getMessage()));
        }
    }

    private static void promoteClassic(List<User_Story__c> userStories) {
        if (userStories.isEmpty())
            return;

        try {
            for (User_Story__c userStory : userStories) {
                createPromotion(userStory);
            }

            insertPromotions();
        } catch (Exception e) {
            userStories[0].addError(returnValidationError(e.getMessage()));
        }
    }

    private static void createPromotion(User_Story__c userStoryRecord) {
        Promotion__c promotion = createPromotionRecord(userStoryRecord);
        String key = userStoryRecord.Project__c + '_' + promotion.Source_Environment__c;
        promotions.add(promotion);
        List<User_Story__c> tempUserStories = new List<User_Story__c>();
        if (storiesByPromotion.containsKey(key)) {
            tempUserStories = storiesByPromotion.get(key);
        }
        tempUserStories.add(userStoryRecord);
        storiesByPromotion.put(key, tempUserStories);
    }

    private static Promotion__c createPromotionRecord(User_Story__c userStoryRecord) {
        Promotion__c promotion = new PromotionOperations(userStoryRecord.Environment__c)
            .projectId(userStoryRecord.Project__c)
            .releaseId(userStoryRecord.Release__c)
            .promotion();
        promotion.Send_Deployment_Complete_email__c = true;

        return promotion;
    }

    private static String returnValidationError(String message) {
        Set<String> labels = new Set<String>{
            Label.COPADO_DEPLOYER_CCM_LICENSE_NOT_ENABLED,
            Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED,
            Label.PROMOTION_FLOW_INACTIVE,
            Label.CCM_DESTINATION_ORG_INVALID,
            Label.CBM_FLOW_INVALID,
            Label.CCM_DESTINATION_ORG_INVALID +
            ' ' +
            Label.CBM_FLOW_INVALID,
            Label.ERROR_PROMOTION_DESTINATION_NOT_FULFILLED
        };

        for (String messageLabel : labels) {
            if (message.contains(messageLabel)) {
                return messageLabel;
            }
        }

        return message;
    }

    private static void insertPromotions() {
        if (!usFlagToStopRecursiveUpdate) {
            usFlagToStopRecursiveUpdate = true;
            Utilities.Secure_DML(new List<Promotion__c>(promotions), Utilities.DML_Action.INS, Schema.SObjectType.Promotion__c);
            insertPromotedUserStories();
        }
    }

    private static void insertPromotedUserStories() {
        List<Promoted_User_Story__c> promotedUserStories = new List<Promoted_User_Story__c>();

        for (Promotion__c promotionRecord : promotions) {
            String uniqueKey = promotionRecord.Project__c + '_' + promotionRecord.Source_Environment__c;

            if (storiesByPromotion.containsKey(uniqueKey)) {
                List<User_Story__c> userStories = storiesByPromotion.get(uniqueKey);

                promotedUserStories.addAll((new PromotedUserStoriesOperations(userStories, promotionRecord).promotedUserStories()));
            }
        }

        Utilities.Secure_DML(promotedUserStories, Utilities.DML_Action.INS, Schema.SObjectType.Promoted_User_Story__c);
        deployPromotions();
    }

    private static void deployPromotions() {
        for (Promotion__c promotionRecord : promotions) {
            if (storiesByPromotion.containsKey(promotionRecord.Project__c + '_' + promotionRecord.Source_Environment__c)) {
                for (
                    User_Story__c userStoryRecord : storiesByPromotion.get(promotionRecord.Project__c + '_' + promotionRecord.Source_Environment__c)
                ) {
                    DeployAPI.deployPromotionAsync(
                        promotionRecord.Id,
                        userStoryRecord.Name,
                        userStoryRecord.Validate_Only__c,
                        userStoryRecord.Promote_as_Single_Step__c,
                        userStoryRecord.Promotion_Test_Level__c
                    );
                }
            }
        }
    }

    public static void executeIndexMetadataJob() {
        if (!metadataIdsToDisable.isEmpty()) {
            indexMetadataJob(metadataIdsToDisable, false);
        }
        if (!metadataIdsToEnable.isEmpty()) {
            indexMetadataJob(metadataIdsToEnable, true);
        }
        if (!userStoryIdsToDisableMC.isEmpty()) {
            Database.executeBatch(new IndexMetadataJobMC().userStories(userStoryIdsToDisableMC).stopIndexing());
        }
        if (!userStoryIdsToEnableMC.isEmpty()) {
            Database.executeBatch(new IndexMetadataJobMC().userStories(userStoryIdsToEnableMC).startIndexing());
        }
    }

    private static void indexMetadataJob(Set<Id> ids, Boolean checkConflicts) {
        IndexMetadataJob imJob = new IndexMetadataJob();
        imJob.zeroizePotentialConflicts = true;
        imJob.checkPotentialConflict = checkConflicts;
        imJob.storyIds = ids;
        Database.executeBatch(imJob);
    }

    // PUBLIC

    public static void updateOutdatedPromotedUserStories() {
        if (newUpdatedUsIds.size() > 0) {
            Set<Id> promotionsToUpdateAsCancelled = new Set<Id>();
            for (Id usId : newUpdatedUsIds.keySet()) {
                Id parentDeploymentFlowId;
                User_Story__c newUserStoryRecord = newUpdatedUsIds.get(usId);
                Boolean isPlatformUserStory = platformUserStory(newUserStoryRecord);
                if (newUserStoryRecord.Project__c != null) {
                    parentDeploymentFlowId = projectsById.get(newUserStoryRecord.Project__c).Deployment_Flow__c;
                } else if (newUserStoryRecord.Release__c != null) {
                    Release__c release = releaseMap.get(newUserStoryRecord.Release__c);
                    if (release.Project__c != null) {
                        parentDeploymentFlowId = release.Project__r.Deployment_Flow__c;
                    }
                }
                if (parentDeploymentFlowId != null) {
                    //since promotedUserStoriesByUserStoryId is ordered by createdDate ASC, initialSourceEnvironmentByUserStoryId should return the initial environment set on the user story
                    Boolean isRevertedToinitialSource = initialSourceEnvironmentByUserStoryId.containsKey(newUserStoryRecord.Id)
                        ? (newUserStoryRecord.Environment__c == initialSourceEnvironmentByUserStoryId.get(newUserStoryRecord.Id))
                        : false;
                    Deployment_Flow__c pipeline = deploymentFlowsById.get(parentDeploymentFlowId);
                    List<Deployment_Flow_Step__c> pipelineConnections = pipeline.Deployment_Flow_Steps__r;
                    sourceEnvironmentIds = new Set<Id>();
                    isNewEnvironmentLowerInPipeline(pipelineConnections, oldUpdatedUsIds.get(usId).Environment__c, newUserStoryRecord.Environment__c);
                    if (!promotedUserStoriesByUserStoryId.isEmpty() && promotedUserStoriesByUserStoryId.containsKey(newUserStoryRecord.Id)) {
                        for (Promoted_User_Story__c promotedUserStory : promotedUserStoriesByUserStoryId.get(newUserStoryRecord.Id)) {
                            if (
                                (isRevertedToinitialSource || sourceEnvironmentIds.contains(promotedUserStory.Promotion__r.Source_Environment__c)) ||
                                (isPlatformUserStory &&
                                isRevertedToinitialSource &&
                                String.valueOf(oldUpdatedUsIds.get(usId).Environment__c) ==
                                String.valueOf(promotedUserStory.Promotion__r.Source_Environment__c))
                            ) {
                                promotedUserStory.Status__c = PromotionConstants.STATUS_OUTDATED;
                                promotedUserStoriesToUpdateAsOutdated.add(promotedUserStory);

                                if (isPlatformUserStory && promotedUserStory.promotion__r.Status__c == PromotionConstants.STATUS_DRAFT) {
                                    promotionsToUpdateAsCancelled.add(promotedUserStory.promotion__c);
                                }
                            }
                        }
                    }
                }
            }

            if (!promotedUserStoriesToUpdateAsOutdated.isEmpty()) {
                update new List<Promoted_User_Story__c>(promotedUserStoriesToUpdateAsOutdated);
            }

            if (!promotionsToUpdateAsCancelled.isEmpty()) {
                updatePromotionsAsCancelled(promotionsToUpdateAsCancelled);
            }
        }
    }

    // PRIVATE

    private static Boolean hasChanged(SObject newRecord, SObject oldRecord, Schema.SObjectField field) {
        return (newRecord.get(field) != oldRecord.get(field));
    }

    private static void getUserStoriesWithRelease(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (oldUserStoryRecord == null || newUserStoryRecord == null) {
            return;
        }

        Boolean isReleaseChanged = hasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Release__c);

        if (isReleaseChanged) {
            releaseIdByUserStoryId.put(newUserStoryRecord.Id, newUserStoryRecord.Release__c);
        }
    }

    private static void getUserStoriesWithdTeam(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (oldUserStoryRecord == null || newUserStoryRecord == null) {
            return;
        }

        Boolean isTeamChanged = hasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Team__c);

        if (isTeamChanged) {
            teamIdByUserStoryId.put(newUserStoryRecord.Id, newUserStoryRecord.Team__c);
        }
    }

    private static void getSprintsForPlannedVelocity(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if ((oldUserStoryRecord == null || oldUserStoryRecord.Sprint__c == null) && newUserStoryRecord.Sprint__c == null) {
            return;
        }

        Boolean isSprintAddedOrChanged = isNewRecordOrHasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Sprint__c);
        Boolean isPlannedPointsAddedOrChanged = isNewRecordOrHasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Total_Story_Points__c);

        if (isSprintAddedOrChanged || isPlannedPointsAddedOrChanged) {
            if (
                isPlannedVelocityRollUpNeeded(newUserStoryRecord) && !userStoryBySprintIdsForPlannedVelocity.containsKey(newUserStoryRecord.Sprint__c)
            ) {
                userStoryBySprintIdsForPlannedVelocity.put(newUserStoryRecord.Sprint__c, newUserStoryRecord);
            }
            if (
                isPlannedVelocityRollUpNeeded(oldUserStoryRecord) &&
                !userStoryBySprintIdsForPlannedVelocity.containsKey(oldUserStoryRecord?.Sprint__c)
            ) {
                userStoryBySprintIdsForPlannedVelocity.put(oldUserStoryRecord.Sprint__c, oldUserStoryRecord);
            }
        }
    }

    private static void getSprintsForActualVelocity(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if ((oldUserStoryRecord == null || oldUserStoryRecord.Sprint__c == null) && newUserStoryRecord.Sprint__c == null) {
            return;
        }

        Boolean isSprintAddedOrChanged = isNewRecordOrHasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Sprint__c);
        Boolean isPlannedPointsAddedOrChanged = isNewRecordOrHasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Total_Story_Points__c);
        Boolean isStatusAddedOrChanged = isNewRecordOrHasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Status__c);

        if ((isSprintAddedOrChanged || isPlannedPointsAddedOrChanged || isStatusAddedOrChanged)) {
            if (
                isActualVelocityRollUpNeeded(newUserStoryRecord) && !userStoryBySprintIdsForActualVelocity.containsKey(newUserStoryRecord.Sprint__c)
            ) {
                userStoryBySprintIdsForActualVelocity.put(newUserStoryRecord.Sprint__c, newUserStoryRecord);
            }
            if (
                isActualVelocityRollUpNeeded(oldUserStoryRecord) && !userStoryBySprintIdsForActualVelocity.containsKey(oldUserStoryRecord.Sprint__c)
            ) {
                userStoryBySprintIdsForActualVelocity.put(oldUserStoryRecord.Sprint__c, oldUserStoryRecord);
            }
        }
    }

    private static void prepareCompletedUserStories(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (String.isBlank(newUserStoryRecord.Status__c)) {
            return;
        }

        Boolean isStatusChanged = hasChanged(newUserStoryRecord, oldUserStoryRecord, User_Story__c.Status__c);
        Boolean isUSValidToProcess = isStatusChanged && dependencyCompletedStatus.contains(newUserStoryRecord?.Status__c);

        if (isUSValidToProcess) {
            completedUSIdsForDependencies.add(newUserStoryRecord.Id);
        }
    }

    private static void updateSprintsPlannedVelocity() {
        if (hasUserStoriesToProcess(userStoryBySprintIdsForPlannedVelocity)) {
            updateVelocity(Schema.SObjectType.Sprint__c.fields.Planned_Velocity__c, userStoryBySprintIdsForPlannedVelocity.values(), '');
        }
    }

    private static void updateSprintsActualVelocity() {
        if (hasUserStoriesToProcess(userStoryBySprintIdsForActualVelocity)) {
            updateVelocity(
                Schema.SObjectType.Sprint__c.fields.Actual_Velocity__c,
                userStoryBySprintIdsForActualVelocity.values(),
                actualyVelocityStatusCondition(actualVelocityStatus)
            );
        }
    }

    private static Boolean isNewRecordOrHasChanged(SObject newRecord, SObject oldRecord, Schema.SObjectField field) {
        return ((Trigger.isInsert && newRecord.get(field) != null) || (oldRecord != null && hasChanged(newRecord, oldRecord, field)));
    }

    private static Boolean isPlannedVelocityRollUpNeeded(User_Story__c record) {
        return (record?.Sprint__c != null && record?.Total_Story_Points__c != null);
    }

    private static Boolean hasUserStoriesToProcess(Map<Id, User_Story__c> recordsBySprintId) {
        return !recordsBySprintId.isEmpty() && recordsBySprintId.values() != null && !recordsBySprintId.values().isEmpty();
    }

    private static Boolean isActualVelocityRollUpNeeded(User_Story__c record) {
        Boolean isRollupNeeded = (String.isNotBlank(record?.Status__c) &&
            actualVelocityStatus.contains(record?.Status__c) &&
            record?.Sprint__c != null &&
            record?.Total_Story_Points__c != null)
            ? true
            : false;

        return isRollupNeeded;
    }

    private static void updateVelocity(Schema.Describefieldresult rollUpField, List<User_Story__c> userStories, String additionalCondition) {
        CopadoRollup.RollUpContext rollupContext = new CopadoRollup.RollUpContext(
            Sprint__c.SobjectType,
            User_Story__c.SobjectType,
            Schema.SObjectType.User_Story__c.fields.Sprint__c,
            additionalCondition
        );

        rollupContext.add(
            new CopadoRollup.RollupSummaryField(
                rollUpField,
                Schema.SObjectType.User_Story__c.fields.Total_Story_Points__c,
                CopadoRollup.OperationEnum.Sum
            )
        );

        Sobject[] sprints = CopadoRollup.rollUp(rollupContext, userStories);

        if (!sprints.isEmpty()) {
            update sprints;
        }
    }

    private static String actualyVelocityStatusCondition(Set<String> statuses) {
        return 'Status__c IN (\'' + String.join((Iterable<String>) statuses, '\', \'') + '\')';
    }

    /**
     * New ability to customize the calculation of actual velocity based on custom metadata 'Actual_Velocity_Statuses'. Default value is 'Completed'
     * New ability to customize the sprint complete 'Sprint_Complete'. default value is 'In Progress'
     * @param devName name of the custom metadata that you want to perform
     * @param defaultValue default value for the action
     * @return
     */
    private static Set<String> getCustomMetadataValues(String devName, String defaultValue) {
        Set<String> customMetadataValuesSet = new Set<String>();
        for (Copado_Setting__mdt copadoSetting : [SELECT Id, Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = :devName LIMIT 1]) {
            if (String.isNotBlank(copadoSetting.Text_Field__c)) {
                for (String value : copadoSetting.Text_Field__c.split(',')) {
                    value = value.trim();
                    customMetadataValuesSet.add(value);
                }
            } else {
                customMetadataValuesSet.add(defaultValue);
            }
        }
        return customMetadataValuesSet;
    }

    private static void updatePromotionsAsCancelled(Set<Id> promotionsToUpdateAsCancelled) {
        List<Promotion__c> promotionsToUpdate = new List<Promotion__c>();
        for (Id promotionId : promotionsToUpdateAsCancelled) {
            promotionsToUpdate.add(new Promotion__c(Id = promotionId, Status__c = PromotionConstants.STATUS_CANCELLED));
        }
        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update promotionsToUpdate;
        PromotionTriggerHelper.bypassPromotionTrigger = false;
    }

    public static void validatePromoteFieldsOnInsert(User_Story__c userStoryRecord) {
        if (platformUserStory(userStoryRecord) && (userStoryRecord.Promote_and_Deploy__c || userStoryRecord.Promote_Change__c)) {
            userStoryRecord.addError(Label.Can_Not_Promote_If_Either_No_Deployment_Steps_or_Metadata_Commits);
        }
    }

    public static void validatePromoteFieldsOnUpdate(User_Story__c oldUserStoryRecord, User_Story__c newUserStoryRecord) {
        if (
            platformUserStory(newUserStoryRecord) &&
            (!oldUserStoryRecord.Promote_and_Deploy__c && newUserStoryRecord.Promote_and_Deploy__c) &&
            !new ValidateUserStoryHasSomethingToPromote(newUserStoryRecord).execute()
        ) {
            newUserStoryRecord.addError(Label.Can_Not_Promote_If_Either_No_Deployment_Steps_or_Metadata_Commits);
        }
    }
}