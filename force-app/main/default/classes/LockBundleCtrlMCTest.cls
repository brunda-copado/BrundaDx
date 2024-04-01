@IsTest
private with sharing class LockBundleCtrlMCTest {
    @TestSetup
    private static void setupData() {
        User user = getUserStoryBundleUser();
        System.runAs(user) {
            // Setup
            new CopadoLicense().user(user).enableAll().persist();
            createPlatformData();
        }
    }

    @IsTest
    private static void testLockBundleForPlatform() {
        System.runAs(getRunAsUserPlatform()) {
            // Setup
            Flow.mockResponse = flowCompletionEvent(true, '', '');
            Map<Id, User_Story__c> selectedUserStories = new Map<Id, User_Story__c>(
                [
                    SELECT
                        Id,
                        Name,
                        User_Story_Title__c,
                        Environment__c,
                        Org_Credential__c,
                        Project__r.Deployment_Flow__c,
                        Release__r.Project__r.Deployment_Flow__c,
                        Platform__c
                    FROM User_Story__c
                    WHERE Platform__c = 'Other'
                ]
            );

            User_Story__c story = TestDataFactory.createUserStories(
                    1,
                    'My Parent Story',
                    'Approved',
                    null,
                    selectedUserStories.values()[0].Project__c,
                    selectedUserStories.values()[0].Environment__c,
                    selectedUserStories.values()[0].Org_Credential__c,
                    'Utility'
                )
                .get(0);
            story.Is_Bundle__c = true;

            // Exercise
            Test.startTest();
            Artifact__c parentBundle = new Artifact__c(
                Name = 'My_Bundle',
                RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId()
            );
            insert parentBundle;

            Artifact_Version__c bundle = new Artifact_Version__c(Name = 'My_Bundle', Artifact__c = parentBundle.Id);
            String bundleId = UserStoryBundleCtrl.createBundleRecords(
                bundle,
                selectedUserStories.values(),
                new List<MetaDataItem>(),
                new List<MetaDataItem>(),
                new List<MetaDataItem>()
            );

            LockBundleCtrl.lockBundle(story, bundleId);
            Test.stopTest();

            // Verify
            Set<Id> chidrenIds = new Set<Id>();
            User_Story__c resultStory = [
                SELECT Id, User_Story_Title__c, Project__c, Org_Credential__c, Environment__c, Is_Bundle__c, RecordType.Name
                FROM User_Story__c
                WHERE User_Story_Title__c LIKE '%My Parent Story%'
            ];

            Artifact_Version__c resultBundle = [
                SELECT Id, User_Story__c, Status__c, (SELECT User_Story__c FROM Bundled_Stories__r)
                FROM Artifact_Version__c
                WHERE Id = :bundleId
            ];
            System.assertEquals(4, resultBundle.Bundled_Stories__r.size(), 'Size of of bundles stories is not correct');
            for (Bundled_Story__c record : resultBundle.Bundled_Stories__r) {
                chidrenIds.add(record.User_Story__c);
            }
            List<User_Story__c> children = [SELECT Id, Stop_Indexing_Metadata__c, Exclude_From_CBM__c FROM User_Story__c WHERE Id = :chidrenIds];
            System.assertEquals(4, children.size(), 'Size of of child stories is not correct');
            for (User_Story__c item : children) {
                System.assertEquals(true, item.Stop_Indexing_Metadata__c, 'This field should be true');
                System.assertEquals(true, item.Exclude_From_CBM__c, 'This field should be true');
            }

            System.assertEquals(true, resultStory.Is_Bundle__c, 'Is bundle must be True');
            System.assertEquals('Utility', resultStory.RecordType.Name, 'Record type must be Utility');
            System.assertEquals(story.User_Story_Title__c, resultStory.User_Story_Title__c, 'Title is not correct');
            System.assertEquals(story.Project__c, resultStory.Project__c, 'Project is not correct');
            System.assertEquals(story.Org_Credential__c, resultStory.Org_Credential__c, 'Org Credential is not correct');
            System.assertEquals(story.Environment__c, resultStory.Environment__c, 'Environment is not correct');

            System.assertEquals(resultBundle.User_Story__c, resultStory.Id, 'User Story in Bundle is not correct');
            System.assertEquals('Locked', resultBundle.Status__c, 'Status must be Locked');
        }
    }

    private static User getRunAsUserPlatform() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createPlatformData() {
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

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));
        return result;
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