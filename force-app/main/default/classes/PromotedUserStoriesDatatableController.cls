@SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class PromotedUserStoriesDatatableController {
    // PUBLIC

    @AuraEnabled
    public static List<Promoted_User_Story__c> fetchData(String promotionId, String selectFieldSet) {
        return new PromotedUserStoriesSelector()
            .byPromotionIdWithFields(new Set<Id>{ promotionId }, getProcessedFields(Promoted_User_Story__c.SObjectType, selectFieldSet));
    }

    @AuraEnabled
    public static List<User_Story__c> availableUserStories(String promotionId, String selectFieldSet) {
        List<User_Story__c> userStories = new List<User_Story__c>();
        Promotion__c promotion = getPromotion(promotionId);
        Set<Id> alreadyAddedUserStoryIds = alreadyAddedUserStoryIds(new Set<Id>{ promotion.Id });

        if (!promotion.Back_Promotion__c) {
            for (User_Story__c userStory : readyToPromoteWithFields(getProcessedFields(User_Story__c.SObjectType, selectFieldSet), promotion)) {
                if (!alreadyAddedUserStoryIds.contains(userStory.Id)) {
                    userStories.add(userStory);
                }
            }
        } else {
            Id pipelineId = null;
            if (promotion.Project__c != null) {
                pipelineId = promotion.Project__r.Deployment_Flow__c;
            } else if (promotion.Release__c != null) {
                pipelineId = promotion.Release__r.Project__r.Deployment_Flow__c;
            }
            List<Deployment_Flow_Step__c> pipelineConnections = new DeploymentFlowStepsSelector()
                .byPipelineAndSourceEnvironment(pipelineId, promotion.Destination_Environment__c);

            Set<Id> userStoryIds = new Set<Id>();
            if (!pipelineConnections.isEmpty()) {
                for (
                    User_Story__c userStory : GlobalUtilities.getUserStoriesFromFieldsetBehind(
                        getProcessedFields(User_Story__c.SObjectType, selectFieldSet),
                        pipelineConnections.get(0)
                    )
                ) {
                    userStoryIds.add(userStory.Id);
                }

                for (
                    User_Story__c userStory : readyToBackPromoteWithFields(
                        getProcessedFields(User_Story__c.SObjectType, selectFieldSet),
                        userStoryIds
                    )
                ) {
                    if (
                        !alreadyAddedUserStoryIds.contains(userStory.Id) &&
                        (projectMatch(promotion, userStory) ||
                        releaseMatch(promotion, userStory) ||
                        projectAndReleaseMatch(promotion, userStory))
                    ) {
                        userStories.add(userStory);
                    }
                }
            }
        }

        return userStories;
    }

    @AuraEnabled(cacheable=false)
    public static void validateSelectedUserStoriesToPromotion(String promotionId, List<Id> userStoryIds) {
        Set<Id> alreadyAddedUserStoryIds = alreadyAddedUserStoryIds(new Set<Id>{ promotionId });
        userStoryIds.addAll(alreadyAddedUserStoryIds);
        List<User_Story__c> userStories = getUserStories(new Set<Id>(userStoryIds));

        checkSameRelease(userStories);
        checkSameProject(userStories);
    }

    private static void checkSameRelease(List<User_Story__c> userStories) {
        Id firstReleaseId = userStories.get(0).Release__c;
        for (User_Story__c userStory : userStories) {
            if (userStory.Release__c != firstReleaseId) {
                throw new ApplicationException(Label.Add_User_Stories_Different_Releases_Validation);
            }
        }
    }

    private static void checkSameProject(List<User_Story__c> userStories) {
        Id firstProject = userStories.get(0).Project__c;
        for (User_Story__c userStory : userStories) {
            if (userStory.Project__c != firstProject) {
                throw new ApplicationException(Label.Add_User_Stories_Different_Releases_Validation);
            }
        }
    }

    @AuraEnabled(cacheable=false)
    public static void addSelectedUserStoriesToPromotion(String promotionId, List<Id> userStoryIds) {
        Promotion__c promotion = getPromotion(promotionId);
        List<Promoted_User_Story__c> promotedUserStories = new List<Promoted_User_Story__c>();
        List<User_Story__c> userStories = getUserStories(new Set<Id>(userStoryIds));

        for (User_Story__c userStory : userStories) {
            String promotedUserStoryName = promotion.Back_Promotion__c
                ? Label.Back_Promoted_User_Story + ' ' + userStory.Name
                : Label.Promoted_User_Story + ' ' + userStory.Name;
            promotedUserStories.add(
                new Promoted_User_Story__c(Name = promotedUserStoryName, Promotion__c = promotion.Id, User_Story__c = userStory.Id)
            );
        }

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, promotedUserStories);
        insert decision.getRecords();

        if (String.isBlank(promotion.Release__c) && String.isNotBlank(userStories[0].Release__c)) {
            updateReleaseOnPromotion(promotion.Id, userStories[0].Release__c);
        }
    }

    @AuraEnabled
    public static void removeSelectedPromotedUserStories(List<Id> promotedUserStoryIds, String contentDocumentId) {
        if (!promotedUserStoryIds.isEmpty()) {
            List<Promoted_User_Story__c> records = new List<Promoted_User_Story__c>();

            for (Id id : promotedUserStoryIds) {
                records.add(new Promoted_User_Story__c(Id = id));
            }

            Utilities.Secure_DML(records, Utilities.DML_Action.DEL, Schema.SObjectType.Promoted_User_Story__c);

            if (contentDocumentId != null && String.isNotBlank(contentDocumentId)) {
                new Files().deleteContentDocument(contentDocumentId);
            }
        }
    }

    // PRIVATE

    private static List<User_Story__c> readyToPromoteWithFields(Set<String> fields, Promotion__c promotion) {
        List<User_Story__c> result;

        Set<Id> projectIds = promotion.Project__c != null ? new Set<Id>{ promotion.Project__c } : new Set<Id>();
        Set<Id> releaseIds = promotion.Release__c != null ? new Set<Id>{ promotion.Release__c } : new Set<Id>();
        Set<Id> environmentIds = new Set<Id>{ promotion.Source_Environment__c };

        String readyToPromoteCondition = 'Promote_Change__c = true';
        String environmentCondition = ' AND Environment__c IN :environmentIds';
        String projectOrReleaseCondition = '';

        if (!projectIds.isEmpty()) {
            projectOrReleaseCondition += ' AND Project__c IN :projectIds';
        }
        if (!releaseIds.isEmpty()) {
            projectOrReleaseCondition += ' AND Release__c IN :releaseIds';
        }

        if (Schema.SObjectType.User_Story__c.isAccessible()) {
            result = Database.query(getFormattedQuery(fields, readyToPromoteCondition + environmentCondition + projectOrReleaseCondition));
        }
        return result;
    }

    private static List<User_Story__c> readyToBackPromoteWithFields(Set<String> fields, Set<Id> userStoryIds) {
        List<User_Story__c> result;
        if (Schema.SObjectType.User_Story__c.isAccessible()) {
            result = Database.query(getFormattedQuery(fields, 'Id IN :userStoryIds'));
        }
        return result;
    }

    private static String getFormattedQuery(Set<String> fields, String condition) {
        String queryTemplate = 'SELECT {0} FROM User_Story__c WHERE {1} WITH USER_MODE ORDER BY Name desc';
        return String.format(queryTemplate, new List<String>{ String.join(new List<String>(fields), ','), condition });
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Promotion__c getPromotion(String promotionId) {
        List<Promotion__c> promotions = [
            SELECT
                Id,
                Project__c,
                Release__c,
                Source_Environment__c,
                Destination_Environment__c,
                Back_Promotion__c,
                Release__r.Project__r.Deployment_Flow__c,
                Project__r.Deployment_Flow__c
            FROM Promotion__c
            WHERE Id = :promotionId
            WITH USER_MODE
        ];

        return promotions.isEmpty() ? new Promotion__c() : promotions[0];
    }

    private static Boolean projectMatch(Promotion__c promotion, User_Story__c userStory) {
        return String.isNotBlank(promotion.Project__c) && String.isBlank(promotion.Release__c) && promotion.Project__c == userStory.Project__c;
    }

    private static Boolean releaseMatch(Promotion__c promotion, User_Story__c userStory) {
        return String.isNotBlank(promotion.Release__c) && String.isBlank(promotion.Project__c) && promotion.Release__c == userStory.Release__c;
    }

    private static Boolean projectAndReleaseMatch(Promotion__c promotion, User_Story__c userStory) {
        return String.isNotBlank(promotion.Project__c) &&
            String.isNotBlank(promotion.Release__c) &&
            promotion.Project__c == userStory.Project__c &&
            promotion.Release__c == userStory.Release__c;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<User_Story__c> getUserStories(Set<Id> userStoryIds) {
        return [SELECT Id, Name, Project__c, Release__c, Org_Credential__c FROM User_Story__c WHERE Id IN :userStoryIds WITH USER_MODE];
    }

    private static Set<Id> alreadyAddedUserStoryIds(Set<Id> promotionIds) {
        Set<Id> result = new Set<Id>();
        for (Promoted_User_Story__c promotedUserStories : new PromotedUserStoriesSelector().byPromotionId(promotionIds)) {
            result.add(promotedUserStories.User_Story__c);
        }
        return result;
    }

    private static void updateReleaseOnPromotion(String promotionId, String releaseId) {
        PromotionTriggerHelper.bypassPromotionTrigger = true;
        DML.safeUpdate(
            new Promotion__c(Id = promotionId, Release__c = releaseId),
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PromotedUserStoriesDatatableController.updateReleaseOnPromotion'
                }
            )
        );
        PromotionTriggerHelper.bypassPromotionTrigger = false;
    }

    private static Set<String> getProcessedFields(SObjectType objectType, String fieldSet) {
        Set<String> result = new Set<String>();
        if (objectType == User_Story__c.SObjectType) {
            result.addAll(getUserStoryFilterFields());
        }

        for (FieldSetMember field : getFieldSetFields(objectType, fieldSet)) {
            String fieldToAdd = field.getFieldPath();
            if (field.getType() == DisplayType.REFERENCE) {
                if (field.getFieldPath().endsWith('__c')) {
                    fieldToAdd = field.getFieldPath().replace('__c', '__r.Name');
                } else if (field.getFieldPath().endsWith('Id')) {
                    // Trick to no to replace other possible appearances of 'Id' in the field name
                    fieldToAdd = field.getFieldPath() + '__';
                    fieldToAdd = fieldToAdd.replace('Id__', '.Name');
                }
            }
            result.add(fieldToAdd);
        }
        return result;
    }

    private static Set<String> getUserStoryFilterFields() {
        return new Set<String>{
            Schema.SObjectType.User_Story__c.fields.Project__c.getName(),
            Schema.SObjectType.User_Story__c.fields.Release__c.getName()
        };
    }

    private static List<FieldSetMember> getFieldSetFields(SObjectType objectType, String fieldSet) {
        return fflib_SObjectDescribe.getDescribe(objectType).getFieldSets().get(fieldSet).getFields();
    }
}