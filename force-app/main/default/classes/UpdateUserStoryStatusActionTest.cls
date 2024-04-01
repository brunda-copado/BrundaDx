@isTest
public with sharing class UpdateUserStoryStatusActionTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @isTest
    private static void testWithSystemPropertyWithEnvironment() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();

            UpdateUserStoryStatusAction.JobExecutionData executionData = new UpdateUserStoryStatusAction.JobExecutionData();
            executionData.userStoryIds = new List<String>((Set<String>) JSON.deserialize(JSON.serialize(getUserStories()), Set<String>.class));

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .dataJson(JSON.serialize(executionData))
                .status(JobExecutionConstants.STATUS_SUCCESSFUL)
                .pipeline(pipeline.Id)
                .persist();

            System_Property__c propertyWOEnvironment = new System_Property__c();
            propertyWOEnvironment.Pipeline__c = pipeline.Id;
            propertyWOEnvironment.API_Name__c = UpdateUserStoryStatusAction.UPDATE_US_STATUS + 'In_Progress';
            propertyWOEnvironment.Value__c = 'In Progress';

            System_Property__c propertyWithEnvironment = new System_Property__c();
            propertyWithEnvironment.API_Name__c = UpdateUserStoryStatusAction.UPDATE_US_STATUS + 'Completed';
            propertyWithEnvironment.Value__c = 'Completed';
            propertyWithEnvironment.Environment__c = getEnvironment('dev1').Id;

            insert new List<System_Property__c>{ propertyWithEnvironment, propertyWOEnvironment };

            UpdateUserStoryStatusAction.Request request = new UpdateUserStoryStatusAction.Request();
            request.jobExecution = job;

            List<UpdateUserStoryStatusAction.Request> requests = new List<UpdateUserStoryStatusAction.Request>{ request };

            // Exercise
            Test.startTest();
            List<UpdateUserStoryStatusAction.Response> responses = UpdateUserStoryStatusAction.execute(requests);
            Test.stopTest();

            // Verify
            system.assertEquals(true, responses.size() > 0, 'response is there');
            system.assertEquals(true, !responses[0].userStoryIds.isEmpty(), 'callback executed successfully');
            List<User_Story__c> inProgressUS = getUserStoriesWithStatus('In Progress');
            System.assertEquals(inProgressUS.size(), 1, 'In Progress Status has been updated successfully');
            List<User_Story__c> successUS = getUserStoriesWithStatus('Completed');
            System.assertEquals(successUS.size(), 3, 'Completed Status has been updated successfully');
        }
    }

    @isTest
    private static void testWithOutSystemProperties() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();

            UpdateUserStoryStatusAction.JobExecutionData executionData = new UpdateUserStoryStatusAction.JobExecutionData();
            executionData.userStoryIds = new List<String>((Set<String>) JSON.deserialize(JSON.serialize(getUserStories()), Set<String>.class));

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .dataJson(JSON.serialize(executionData))
                .status(JobExecutionConstants.STATUS_SUCCESSFUL)
                .pipeline(pipeline.Id)
                .persist();

            UpdateUserStoryStatusAction.Request request = new UpdateUserStoryStatusAction.Request();
            request.jobExecution = job;

            List<UpdateUserStoryStatusAction.Request> requests = new List<UpdateUserStoryStatusAction.Request>{ request };

            // Exercise
            Test.startTest();
            List<UpdateUserStoryStatusAction.Response> responses = UpdateUserStoryStatusAction.execute(requests);
            Test.stopTest();

            // Verify
            system.assertEquals(true, responses.size() > 0, 'response is there');
            List<User_Story__c> draftUS = getUserStoriesWithStatus('Draft');
            System.assertEquals(draftUS.size(), 4, 'status will not be changed');
        }
    }

    //HELPERS

    private static void createData() {
        new JobTemplate().name('Commit Template').version(1).mockAutomation('Commit').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(
                new Project()
                    .add(new UserStory().status('Draft').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().status('Draft').credential(intCredential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(
                        new UserStory().credential(dev1Credential).status('Draft').add(new UserStoryMetadata().name('TestClass 1').type('ApexClass'))
                    )
                    .add(
                        new UserStory().credential(dev1Credential).status('Draft').add(new UserStoryMetadata().name('TestClass 2').type('ApexClass'))
                    )
            )
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c WITH USER_MODE LIMIT 1];
    }

    private static Set<Id> getUserStories() {
        return new Map<Id, User_Story__c>([SELECT Id, Status__c FROM User_Story__c WITH USER_MODE]).keySet();
    }

    private static List<User_Story__c> getUserStoriesWithStatus(String status) {
        return [SELECT Id, Status__c FROM User_Story__c WHERE Status__c = :status];
    }

    private static Environment__c getEnvironment(string name) {
        return [SELECT Id, Name FROM Environment__c WHERE Name = :name];
    }
}