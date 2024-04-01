@isTest
public with sharing class GitRepoControllerTest {

    private static final String COPADO_NOTIFICATIONS = GitRepoController.COPADO_NOTIFICATIONS;
    private static final String QUERY = GitRepoController.QUERY;

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .assign(new PermissionSetAssignment_t().configureSnapshots())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            insertData();
        }
    }

    @IsTest
    private static void testRefreshBranches() {
        System.runAs(getRunAsUser()) {
            // Setup
            Git_Repository__c repository = getRepository('copado-dx-cmt');

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"copadoJobId":"77ceab1e-68d5-470e-b888-0303e44f16ce","ok":"Job has started!"}', null));

            // Exercise
            Test.startTest();
                GitRepoController.refreshBranches(repository.Id);
            Test.stopTest();

            // Verify
            List<Copado_Notification__c> notifications = getCopadoNotification('DxListRepositoryBranches');
            Assert.areEqual(
                !notifications.isEmpty(), 
                true, 
                'Notification should be created'
            );
        }
    }

    @IsTest
    private static void testRefreshBranchesWithoutRepoId() {
        System.runAs(getRunAsUser()) {
            // Setup

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"copadoJobId":"77ceab1e-68d5-470e-b888-0303e44f16ce","ok":"Job has started!"}', null));

            // Exercise
            Test.startTest();
                GitRepoController.refreshBranches('');
            Test.stopTest();

            // Verify
            List<Copado_Notification__c> notifications = getCopadoNotification('DxListRepositoryBranches');
            Assert.areEqual(
                notifications.isEmpty(), 
                true, 
                'Notification should not be created'
            );
        }
    }

    @isTest
    private static void testFetchBranches(){
        System.runAs(getRunAsUser()) {
            // Setup
            String branchesJSON = '';
            Git_Repository__c repository = getRepository('copado-dx-cmt');

            Attachment branches = new Attachment(Name = GitRepoController.GIT_BRANCHES , ParentId = repository.Id, Body = Blob.valueOf(getBranchesBody()));
            insert branches;
    
            // Exercise
            Test.startTest();
                branchesJSON = GitRepoController.fetchBranches(repository.Id);
            Test.stopTest();
    
            // Verify
            Assert.areEqual(
                String.isNotBlank(branchesJSON), 
                true, 
                'Branches should be existed'
            );
            List<GitRepoController.Branch> parsedBranches = (List<GitRepoController.Branch>) JSON.deserialize(branchesJSON, List<GitRepoController.Branch>.class);
            Assert.areEqual(
                !parsedBranches.isEmpty(), 
                true, 
                'Branches should be existed'
            );
            Assert.areEqual(
                parsedBranches[0].name, 
                'ar-vlocity', 
                'ar-vlocity should be existed'
            );
        }
    }

    @isTest
    private static void testFetchBranchesWithoutAttachment(){
        System.runAs(getRunAsUser()) {
            // Setup
            String branchesJSON = '';
            Git_Repository__c repository = getRepository('copado-dx-cmt');
    
            // Exercise
            Test.startTest();
                branchesJSON = GitRepoController.fetchBranches(repository.Id);
            Test.stopTest();
    
            // Verify
            Assert.areEqual(
                String.isBlank(branchesJSON), 
                true, 
                'Branches should not be existed'
            );
        }
    }

    @isTest
    private static void testFetchBranchesWithoutRepoId(){
        System.runAs(getRunAsUser()) {
            // Setup
            String branchesJSON = '';
            
    
            // Exercise
            Test.startTest();
                branchesJSON = GitRepoController.fetchBranches('');
            Test.stopTest();
    
            // Verify
            Assert.areEqual(
                String.isBlank(branchesJSON), 
                true, 
                'Branches should not be existed'
            );
        }
    }

    @IsTest
    private static void testCallDeleteBranches() {
        System.runAs(getRunAsUser()) {
            // Setup
            Git_Repository__c repository = getRepository('copado-dx-cmt');

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"copadoJobId":"77ceab1e-68d5-470e-b888-0303e44f16ce","ok":"Job has started!"}', null));

            // Exercise
            Test.startTest();
                GitRepoController.areGitBranchesDeleted(repository.Id, getDeleteBranches()) ;
            Test.stopTest();

            // Verify
            List<Copado_Notification__c> notifications = getCopadoNotification('GitDeleteBranches');
            Assert.areEqual(
                !notifications.isEmpty(), 
                true, 
                'Notification should be created'
            );
        }
    }

    @IsTest
    private static void testCallDeleteBranchesWithoutInvalidResponse() {
        System.runAs(getRunAsUser()) {
            Boolean isDeleted;

            // Setup
            Git_Repository__c repository = getRepository('copado-dx-cmt');

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"copadoJobId":"","ok":"Job has started!"}', null));

            // Exercise
            Test.startTest();
                isDeleted = GitRepoController.areGitBranchesDeleted(repository.Id, getDeleteBranches()) ;
            Test.stopTest();

            // Verify
            Assert.areEqual(
                isDeleted, 
                false, 
                'Notification should not be created when jobId is empty'
            );
        }
    }

    @IsTest
    private static void testCallDeleteBranchesWithBlankResponse() {
        System.runAs(getRunAsUser()) {
            Boolean isDeleted;
            // Setup
            Git_Repository__c repository = getRepository('copado-dx-cmt');

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('', null));

            // Exercise
            Test.startTest();
                isDeleted = GitRepoController.areGitBranchesDeleted(repository.Id, getDeleteBranches()) ;
            Test.stopTest();

            // Verify
            Assert.areEqual(
                isDeleted, 
                false, 
                'Notification should not be created when jobId is empty'
            );
        }
    }

   

    @isTest
    private static void testPushTopicCreation(){
        System.runAs(getRunAsUser()) {
            // EXERCISE
            GitRepoController.PushTopicCreationResponse result = GitRepoController.CreateCopadoNotificationPushTopic();
            // VERIFY
            List<PushTopic> copadoNotification = [
                SELECT
                    Id,
                    Name,
                    Query,
                    ApiVersion,
                    NotifyForOperationCreate,
                    NotifyForOperationUpdate,
                    NotifyForOperationDelete,
                    NotifyForOperationUndelete,
                    NotifyForFields
                FROM PushTopic
                WHERE Name = :COPADO_NOTIFICATIONS
                LIMIT 1
            ];
            Assert.areEqual(!copadoNotification.isEmpty(), true,'Push Topic Name should be fetched');
            Assert.areEqual(COPADO_NOTIFICATIONS, copadoNotification[0].Name, 'Push Topic Name should be CopadoNotifications');
            Assert.areEqual(true, result.isSuccess, 'Result should be success');
            Assert.areEqual(QUERY, copadoNotification[0].Query, 'Push Topic Query is not correct');
            Assert.areEqual(32.0, copadoNotification[0].ApiVersion, 'Push Topic ApiVersion is not correct');
            Assert.areEqual(true, copadoNotification[0].NotifyForOperationCreate, 'Push Topic NotifyForOperationCreate should be true');
            Assert.areEqual(true, copadoNotification[0].NotifyForOperationUpdate, 'Push Topic NotifyForOperationUpdate should be true');
            Assert.areEqual(true, copadoNotification[0].NotifyForOperationDelete, 'Push Topic NotifyForOperationDelete should be true');
            Assert.areEqual(true, copadoNotification[0].NotifyForOperationUndelete, 'Push Topic NotifyForOperationUndelete should be true');
            Assert.areEqual('All', copadoNotification[0].NotifyForFields, 'Push Topic NotifyForFields should be All');
        }
    }

    @IsTest
    private static void testCopadoNotificationSkipCreation() {
        System.runAs(getRunAsUser()) {
            // SETUP
            PushTopic pushTopic = new PushTopic();
            pushTopic.Name = COPADO_NOTIFICATIONS;
            pushTopic.Query = QUERY;
            pushTopic.ApiVersion = 32.0;
            pushTopic.NotifyForOperationCreate = true;
            pushTopic.NotifyForOperationUpdate = true;
            pushTopic.NotifyForOperationUndelete = true;
            pushTopic.NotifyForOperationDelete = true;
            pushTopic.NotifyForFields = 'All';
            insert pushTopic;
            // EXERCISE
            GitRepoController.PushTopicCreationResponse result = GitRepoController.CreateCopadoNotificationPushTopic();
            // VERIFY
            List<PushTopic> copadoNotification = [
                SELECT Id, Name
                FROM PushTopic
                WHERE Name = :COPADO_NOTIFICATIONS
            ];
            Assert.areEqual(true, result.isSuccess, 'Result should be success');
            Assert.areEqual(1, copadoNotification.size(), 'Push Topic already exists');
        }
    }

    //HELPER

    private static String getBranchesBody(){
        String gitBranches = '[{ "name": "HEAD", "type": "Git", "lastUpdate": "1702023439000" },';
        gitBranches +='{ "name": "ar-vlocity", "type": "Git", "lastUpdate": "1676535428000" },';
        gitBranches +='{ "name": "dev1", "type": "Git", "lastUpdate": "1687348145000" },';
        gitBranches +='{ "name": "dev2", "type": "Git", "lastUpdate": "1707322254000" },';
        gitBranches +='{ "name": "dev3", "type": "Git", "lastUpdate": "1707322254000" }]';

        return gitBranches;
    }

    private static String getDeleteBranches(){
       return  '{ "gitBranches" : ["dev3"]}';
    }

    private static Git_Repository__c getRepository(String name) {
        return [SELECT Name FROM Git_Repository__c WHERE Name = :name WITH SECURITY_ENFORCED LIMIT 1];
    }

    private static List<Copado_Notification__c> getCopadoNotification(String copadoNotificationName) {
        return [SELECT Id FROM Copado_Notification__c WHERE Name=:copadoNotificationName WITH SECURITY_ENFORCED LIMIT 1];
    }

    private static void insertData() {
        
        new GitRepository()
                .name('copado-dx-cmt')
                .gitProvider('Bitbucket')
                .sourceFormat('Metadata')
                .uri('git@github.com:rsluzhenko/copado-dx-cmt.git')
                .persist();
        
        new JobTemplate().name('Snapshot Template').mockAutomation(ActionConstants.TAKE_SNAPSHOT).add(new JobStep()).persist();

        Credential dev1Credential = new Credential().oAuthSignature('authentication');
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .repository(getRepository('copado-dx-cmt').Id)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(new Project())
            .persist();
    }

   

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline(String platform) {
        return [SELECT Id, Active__c FROM Deployment_Flow__c WHERE Platform__c = :platform LIMIT 1];
    }
}