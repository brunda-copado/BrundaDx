@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class UpdateUserStoryStatusAction {
    @Testvisible
    private static final String UPDATE_US_STATUS = 'Update_US_Status_';

    @InvocableMethod(Label='Update User Story Status' category='Copado Multi-Cloud')
    global static List<Response> execute(List<Request> requests) {
        return updateUserStoryStatus(requests);
    }

    //Private

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<Response> updateUserStoryStatus(List<Request> requests) {
        Request request = requests[0];
        Response result = new Response();

        JobExecution__c job = ((JobExecution__c) request.jobExecution);
        result.userStoryIds = filterAndUpdateUserStories(job);

        return new List<Response>{ result };
    }

    private static List<Id> filterAndUpdateUserStories(JobExecution__c job) {
        Map<Id, String> statusByEnvironmentIds = new Map<Id, String>();
        List<System_Property__c> statusSystemProperties = new List<System_Property__c>();
        List<User_Story__c> fetchedUserStories = new List<User_Story__c>();

        JobExecutionData data = (JobExecutionData) JSON.deserialize(job.DataJSON__c, JobExecutionData.class);
        if (data.userStoryIds != null && !data.userStoryIds.isEmpty()) {
            Set<Id> environmentIds = new Set<Id>();

            fetchedUserStories = fetchUserStoriesById(data.userStoryIds);
            for (User_Story__c userStory : fetchedUserStories) {
                environmentIds.add(userStory.Environment__c);
            }
            statusSystemProperties = fetchSystemProperties(job.Pipeline__c, environmentIds);
            statusByEnvironmentIds = prepareSystemPropertiesByEnvironment(statusSystemProperties);
        }
        updateUserStories(fetchedUserStories, statusByEnvironmentIds, statusSystemProperties);
        return data.userStoryIds;
    }

    private static void updateUserStories(
        List<User_Story__c> fetchedUserStories,
        Map<Id, String> statusByEnvironmentIds,
        List<System_Property__c> statusSystemProperties
    ) {
        List<User_Story__c> userStoriesToUpdate = new List<User_Story__c>();

        for (User_Story__c userStory : fetchedUserStories) {
            if (statusByEnvironmentIds.containsKey(userStory.Environment__c)) {
                userStory.Status__c = statusByEnvironmentIds.get(userStory.Environment__c);
                userStoriesToUpdate.add(userStory);
            } else {
                userStoriesToUpdate.add(assignUserStoryStatusWithPipeline(statusSystemProperties, userStory));
            }
        }

        if (!userStoriesToUpdate.isEmpty()) {
            UserStories.bypassTrigger = true;
            DML.safeUpdate(
                userStoriesToUpdate,
                String.format(
                    Label.ErrorWhileUpdating,
                    new List<String>{
                        User_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'UpdateUserStoryStatusAction.execute.updateUserStoryStatus.filterAndUpdateUserStories'
                    }
                )
            );
            UserStories.bypassTrigger = false;
        }
    }

    private static Map<Id, String> prepareSystemPropertiesByEnvironment(List<System_Property__c> statusSystemProperties) {
        Map<Id, String> valueByEnvironmentIds = new Map<Id, String>();
        for (System_Property__c sysProperty : statusSystemProperties) {
            if (String.isNotBlank(sysProperty.Environment__c) && String.isNotBlank(sysProperty.Value__c)) {
                valueByEnvironmentIds.put(sysProperty.Environment__c, sysProperty.Value__c);
            }
        }
        return valueByEnvironmentIds;
    }

    private static User_Story__c assignUserStoryStatusWithPipeline(List<System_Property__c> statusSystemProperties, User_Story__c userStory) {
        for (System_Property__c sysProperty : statusSystemProperties) {
            if (String.isNotBlank(sysProperty.Pipeline__c) && String.isNotBlank(sysProperty.Value__c)) {
                userStory.Status__c = sysProperty.Value__c;
                break;
            }
        }
        return userStory;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<System_Property__c> fetchSystemProperties(Id pipelineId, set<Id> environmentIds) {
        String updateUSStatus = UPDATE_US_STATUS + '%';
        return [
            SELECT Id, Environment__c, Pipeline__c, Value__c
            FROM System_Property__c
            WHERE (Pipeline__c = :pipelineId OR Environment__c IN :environmentIds) AND API_Name__c LIKE :updateUSStatus
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<User_Story__c> fetchUserStoriesById(List<Id> userStoryIds) {
        return [SELECT Id, Environment__c, Status__c FROM User_Story__c WHERE Id IN :userStoryIds WITH USER_MODE];
    }

    // INNER

    global class Request {
        @InvocableVariable(label='Job Execution' description='Job Execution from actioncallback')
        global sObject jobExecution;

        @InvocableVariable(label='Status' description='Job Execution status from actioncallback')
        global String status;
    }

    global class Response {
        @InvocableVariable
        global List<Id> userStoryIds;
    }

    //WRAPPER
    @TestVisible
    private class JobExecutionData {
        @TestVisible
        private List<String> userStoryIds;
    }
}