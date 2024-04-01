@IsTest
private class CreateUserStoryBundleServiceImplTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = getUserStoryBundleUser();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void createBundle() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories()) {
                userStoryIds.add(userStory.Id);
            }

            Artifact_Version__c packageVersion = new Artifact_Version__c();
            packageVersion.Name = 'Poc';

            Actions.CreateUserStoryBundleRequest request = new Actions.CreateUserStoryBundleRequest();
            request.packageVersion = packageVersion;
            request.userStoryIds = userStoryIds;

            // Exercise
            Test.startTest();
            Actions.UserStoryBundleService.create(request);
            Test.stopTest();

            // Verify
            List<Bundled_Story__c> bundledUserStories = [SELECT Id FROM Bundled_Story__c];
            System.assertEquals(2, bundledUserStories.size(), '2 user stories added to the package version as bundled user stories');
        }
    }

    // HELPERS

    private static void createData() {
        new JobTemplate().name('Commit Template').version(1).mockAutomation('Commit').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(
                new Project()
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 1').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 2').type('ApexClass')))
            )
            .persist();
    }

    private static List<User_Story__c> getUserStories() {
        return [SELECT Id FROM User_Story__c LIMIT 2];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserStoryBundleUser() {
        return (User) new User_t()
            .assign(getCopadoUserPermissionSetAssignment())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
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