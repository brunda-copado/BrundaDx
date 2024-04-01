@isTest
private with sharing class UserStoryBundleUserStoriesTableCtrlTest {
    @TestSetup
    private static void setupData() {
        User user = getUserStoryBundleUser();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
            createBundle();
        }
    }

    @IsTest
    private static void testAddUserStoriesHappyPath() {
        System.runAs(getRunAsUser()) {
            // Setup
            Artifact_Version__c packageVersionRecord = getPackageVersion();
            User_Story__c userStory = getUserStories()[0].clone(false, true, false, false);
            List<Id> userStoryIds = new List<Id>{ userStory.Id };

            // Exercise

            Test.startTest();

            UserStoryBundleUserStoriesTableCtrl.addSelectedUserStories(packageVersionRecord.Id, userStoryIds);

            Test.stopTest();

            // Verify
            List<Bundled_Story__c> bundledUserStories = [SELECT Id FROM Bundled_Story__c WHERE User_Story__c IN :userStoryIds WITH SECURITY_ENFORCED];
            System.assertEquals(!bundledUserStories.isEmpty(), true, 'Bundled User Stories should be created');
        }
    }

    @IsTest
    private static void testRemoveUserStoriesHappyPath() {
        System.runAs(getRunAsUser()) {
            // Setup
            Artifact_Version__c packageVersionRecord = getPackageVersion();

            Bundled_Story__c bundledStory = [
                SELECT Id, User_Story__c
                FROM Bundled_Story__c
                WHERE User_Story__c != NULL
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            System.assertEquals(bundledStory != null, true, 'Bundled Story associated to User story should exists');
            // Exercise
            Test.startTest();
            UserStoryBundleUserStoriesTableCtrl.removeSelectedUserStories(packageVersionRecord.Id, new List<Id>{ bundledStory.Id });
            Test.stopTest();

            // Verify
            List<Bundled_Story__c> bundledUserStories = [SELECT Id FROM Bundled_Story__c WHERE Id = :bundledStory.Id WITH SECURITY_ENFORCED];
            System.assertEquals(bundledUserStories.isEmpty(), true, 'Bundled User story record should be deleted');
        }
    }

    @IsTest
    private static void testAvailableUserStoriesHappyPath() {
        System.runAs(getRunAsUser()) {
            // Setup
            Artifact_Version__c packageVersionRecord = getPackageVersion();

            // Exercise
            Test.startTest();
            List<Id> availableUserStoryIds = UserStoryBundleUserStoriesTableCtrl.fetchAvailableUserStoryIds(packageVersionRecord.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(availableUserStoryIds.size(), 1, 'user stories should be available');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        new JobTemplate().name('Commit Template').mockAutomation(ActionConstants.COMMIT_ACTION).add(new JobStep()).persist();

        Credential source = new Credential();

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().platform('Other').add(new Credential())
                    )
                    .branch('dev1')
            )
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
                    .branch('dev2')
            )
            .add(
                new Project()
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();
    }

    private static String createBundle() {
        List<User_Story__c> userStories = getUserStories();
        Artifact__c parentBundle = new Artifact__c(
            Name = 'My_Bundle',
            RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId()
        );
        insert parentBundle;

        Artifact_Version__c bundle = new Artifact_Version__c(Name = 'My_Bundle', Artifact__c = parentBundle.Id);
        insert bundle;

        insert new List<Bundled_Story__c>{
            new Bundled_Story__c(User_Story__c = userStories[0].Id, Package_Version__c = bundle.Id),
            new Bundled_Story__c(User_Story__c = userStories[1].Id, Package_Version__c = bundle.Id),
            new Bundled_Story__c(User_Story__c = userStories[2].Id, Package_Version__c = bundle.Id)
        };

        return bundle.Id;
    }

    private static List<User_Story__c> getUserStories() {
        return [
            SELECT Id, Name, User_Story_Title__c, Environment__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Platform__c
            FROM User_Story__c
            WHERE Platform__c = 'Other'
        ];
    }

    private static Artifact_Version__c getPackageVersion() {
        return [SELECT Id, Status__c FROM Artifact_Version__c WHERE Name = 'My_Bundle' WITH SECURITY_ENFORCED LIMIT 1];
    }

    private static User getUserStoryBundleUser() {
        return (User) new User_t()
            .assign(getCopadoUserPermissionSetAssignment())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
    }

    private static PermissionSetAssignment_t getCopadoUserPermissionSetAssignment() {
        PermissionSetAssignment_t copadoUserPermissionSetAssignment = new PermissionSetAssignment_t().copadoUser();
        if (!customPermissionAlreadyAssigned()) {
            copadoUserPermissionSetAssignment.add(new CustomPermission_t().userStoryBundles());
        }
        return copadoUserPermissionSetAssignment;
    }

    private static Boolean customPermissionAlreadyAssigned() {
        return [
                SELECT COUNT()
                FROM SetupEntityAccess
                WHERE
                    SetupEntityId IN (
                        SELECT Id
                        FROM CustomPermission
                        WHERE DeveloperName = :CustomPermissionConstants.USER_STORY_BUNDLE_CUSTOM_PERMISSION
                    )
                    AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Copado_User')
            ] > 0;
    }
}