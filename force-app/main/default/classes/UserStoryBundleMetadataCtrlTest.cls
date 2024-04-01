@IsTest
private with sharing class UserStoryBundleMetadataCtrlTest {
    @TestSetup
    private static void setupData() {
        User user = getUserStoryBundleUser();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void testCreateBundleHappyPathForPlatform() {
        System.runAs(getRunAsUser()) {
            // Setup
            String bundleId = createBundle();

            // Exercise
            Test.startTest();
            List<Id> userStoryIds = UserStoryBundleMetadataCtrl.getUserStoryIds(bundleId);
            Test.stopTest();

            // Verify
            System.assertEquals(4, userStoryIds.size(), 'Number of user stories should match');
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
        Map<Id, User_Story__c> selectedUserStories = new Map<Id, User_Story__c>(
            [
                SELECT
                    Id,
                    Name,
                    User_Story_Title__c,
                    Environment__c,
                    Project__r.Deployment_Flow__c,
                    Release__r.Project__r.Deployment_Flow__c,
                    Platform__c
                FROM User_Story__c
                WHERE Platform__c = 'Other'
            ]
        );

        Artifact__c parentBundle = new Artifact__c(
            Name = 'My_Bundle',
            RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId()
        );
        insert parentBundle;

        Artifact_Version__c bundle = new Artifact_Version__c(Name = 'My_Bundle', Artifact__c = parentBundle.Id);

        // Exercise
        String bundleId = UserStoryBundleCtrl.createBundleRecords(
            bundle,
            selectedUserStories.values(),
            new List<MetaDataItem>(),
            new List<MetaDataItem>(),
            new List<MetaDataItem>()
        );
        return bundleId;
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