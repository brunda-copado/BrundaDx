@IsTest
private with sharing class IndexMetadataJobMCTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void enableIndexingInProject() {
        System.runAs(getRunAsUser()) {
            // Setup
            Project__c project = getProject('Project1');

            // Exercise
            Test.startTest();
            Database.executeBatch(new IndexMetadataJobMC().projects(new Set<Id>{ project.Id }).startIndexing());
            Test.stopTest();

            // Verify
            Integer potentialConflicts = [
                SELECT COUNT()
                FROM User_Story_Metadata__c
                WHERE User_Story__r.Project__c = :project.Id AND Status__c = 'Potential Conflict'
            ];
            Assert.areEqual(3, potentialConflicts, 'All metadata should be marked as Potential Conflict');
        }
    }

    @IsTest
    private static void disableIndexingInProject() {
        System.runAs(getRunAsUser()) {
            // Setup
            Project__c project = getProject('Project1');

            // Exercise
            Test.startTest();
            Database.executeBatch(new IndexMetadataJobMC().projects(new Set<Id>{ project.Id }).stopIndexing());
            Test.stopTest();

            // Verify
            Integer potentialConflicts = [
                SELECT COUNT()
                FROM User_Story_Metadata__c
                WHERE User_Story__r.Project__c = :project.Id AND Status__c = 'Potential Conflict'
            ];
            Assert.areEqual(0, potentialConflicts, 'All metadata should be removed from Potential Conflict');
        }
    }

    @IsTest
    private static void enableIndexingInUserStory() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStory('Project1 - US1');

            // Exercise
            Test.startTest();
            Database.executeBatch(new IndexMetadataJobMC().userStories(new Set<Id>{ userStory.Id }).startIndexing());
            Test.stopTest();

            // Verify
            Integer potentialConflicts = [SELECT COUNT() FROM User_Story_Metadata__c WHERE Status__c = 'Potential Conflict'];
            Assert.areEqual(3, potentialConflicts, 'All metadata should be marked as Potential Conflict');
        }
    }

    @IsTest
    private static void disableIndexingInUserStory() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStory('Project1 - US1');

            // Exercise
            Test.startTest();
            Database.executeBatch(new IndexMetadataJobMC().userStories(new Set<Id>{ userStory.Id }).stopIndexing());
            Test.stopTest();

            // Verify
            Integer potentialConflicts = [
                SELECT COUNT()
                FROM User_Story_Metadata__c
                WHERE User_Story__c = :userStory.Id AND Status__c = 'Potential Conflict'
            ];
            Assert.areEqual(0, potentialConflicts, 'All metadata from user story should be removed from Potential Conflict');
        }
    }

    @IsTest
    private static void scheduleJob() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            System.schedule('IndexMetadataJobMCTest', '0 0 0/1 ? * *', new IndexMetadataJobMC());
            Database.executeBatch(new IndexMetadataJobMC());
            Test.stopTest();

            // Verify
            Integer potentialConflicts = [SELECT COUNT() FROM User_Story_Metadata__c WHERE Status__c = 'Potential Conflict'];
            Assert.areEqual(6, potentialConflicts, 'All metadata should be marked as Potential Conflict');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Project__c getProject(String name) {
        return [SELECT Id FROM Project__c WHERE Name = :name LIMIT 1];
    }

    private static User_Story__c getUserStory(String title) {
        return [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :title LIMIT 1];
    }

    private static void createData() {
        createPipeline('Project1', 'Class1');
        createPipeline('Project2', 'Class2');
    }

    private static void createPipeline(String projectName, String className) {
        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(integration, prod).branch('int'))
            .add(
                new Project()
                    .name(projectName)
                    .add(
                        new UserStory()
                            .title(projectName + ' - US1')
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name(className).type('ApexClass').directory('myFolder'))
                    )
                    .add(
                        new UserStory()
                            .title(projectName + ' - US2')
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name(className).type('ApexClass').directory('myFolder'))
                    )
                    .add(
                        new UserStory()
                            .title(projectName + ' - US3')
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name(className).type('ApexClass').directory('myFolder'))
                    )
            )
            .persist();
    }
}