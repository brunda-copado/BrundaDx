public with sharing class OrderDeploymentStepsController {
    // PUBLIC

    @AuraEnabled(cacheable=false)
    public static List<JobStep__c> getFilteredDeploymentSteps(Id parentId, Boolean isValidation) {
        try {
            List<JobStep__c> result = getAllDeploymentSteps(parentId);
            if (!result.isEmpty()) {
                result = filterSteps(result, parentId, isValidation);
            }
            return result;
        } catch (Exception e) {
            throw new ApplicationException(e.getStackTraceString());
        }
    }

    public static List<JobStep__c> getAllDeploymentSteps(Id parentId) {
        return getDeploymentSteps(getUserStoryIds(parentId));
    }

    // PRIVATE

    private static List<JobStep__c> filterSteps(List<JobStep__c> deploymentSteps, Id parentId, Boolean isValidation) {
        Id pipelineId = null;
        Id destinationId = null;
        Boolean isBackPromotion = false;

        String objectType = getObjectType(parentId);
        if (isPromotion(objectType)) {
            List<Promotion__c> promotions = getPromotions(parentId);
            if (!promotions.isEmpty()) {
                Promotion__c promotion = promotions[0];
                pipelineId = new FindPipeline().fromObject(promotion);
                destinationId = promotion.Destination_Environment__c;
                isBackPromotion = promotion.Back_Promotion__c;
            }
        } else if (isUserStory(objectType)) {
            List<User_Story__c> userStories = getUserStories(parentId);
            if (!userStories.isEmpty()) {
                User_Story__c userStory = userStories[0];
                pipelineId = new FindPipeline().fromObject(userStory);
                destinationId = findNextEnvironment(pipelineId, userStory.Environment__c);
            }
        }

        return new DeploymentTaskStepChecker(deploymentSteps)
            .pipelineId(pipelineId)
            .destinationId(destinationId)
            .backPromotion(isBackPromotion)
            .isValidation(isValidation)
            .run();
    }

    private static String getObjectType(Id parentId) {
        return parentId.getSObjectType().getDescribe(SObjectDescribeOptions.DEFAULT).getName();
    }

    private static Set<Id> getUserStoryIds(Id parentId) {
        Set<Id> result = new Set<Id>();

        String objectType = getObjectType(parentId);
        if (isPromotion(objectType)) {
            for (Promoted_User_Story__c promotedUserStory : getPromotedUserStories(parentId)) {
                result.add(promotedUserStory.User_Story__c);
            }
        } else if (isUserStory(objectType)) {
            result.add(parentId);
        }
        return result;
    }

    private static Boolean isPromotion(String objectType) {
        return objectType == Schema.SObjectType.Promotion__c.getName();
    }

    private static Boolean isUserStory(String objectType) {
        return objectType == Schema.SObjectType.User_Story__c.getName();
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<Promotion__c> getPromotions(Id parentId) {
        return [
            SELECT Id, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Destination_Environment__c, Back_Promotion__c
            FROM Promotion__c
            WHERE Id = :parentId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<User_Story__c> getUserStories(Id parentId) {
        return [
            SELECT Id, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Environment__c
            FROM User_Story__c
            WHERE Id = :parentId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<JobStep__c> getDeploymentSteps(Set<Id> userStoryIds) {
        return [
            SELECT
                Id,
                CustomType__c,
                Type__c,
                ConfigJson__c,
                ExecutionSequence__c,
                Name,
                Order__c,
                UserStory__c,
                UserStory__r.Name,
                UserStory__r.User_Story_Title__c
            FROM JobStep__c
            WHERE UserStory__c IN :userStoryIds
            WITH USER_MODE
            ORDER BY Order__c ASC, UserStory__r.Name ASC
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<Promoted_User_Story__c> getPromotedUserStories(Id parentId) {
        return [SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c = :parentId WITH USER_MODE];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Id findNextEnvironment(Id pipelineId, Id environmentId) {
        Id result = null;
        List<Deployment_Flow_Step__c> connections = [
            SELECT Destination_Environment__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :pipelineId AND Source_Environment__c = :environmentId
            WITH USER_MODE
            LIMIT 1
        ];
        if (!connections.isEmpty()) {
            result = connections[0].Destination_Environment__c;
        }
        return result;
    }
}