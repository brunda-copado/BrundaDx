@IsTest
private class LockBundleCtrlTest {
    @TestSetup
    private static void setupData() {
        createData();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            // Setup
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void testLockBundle() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c story = createBundleStory();
            Artifact_Version__c bundle = getPackageVersionByName('My_Bundle');

            // Exercise
            Test.startTest();
            LockBundleCtrl.lockBundle(story, bundle.Id);
            Test.stopTest();

            // Verify
            User_Story__c resultStory = [
                SELECT Id, User_Story_Title__c, Project__c, Org_Credential__c, Environment__c, Is_Bundle__c, RecordType.Name
                FROM User_Story__c
                WHERE User_Story_Title__c LIKE '%My Parent Story%'
            ];

            System.assertEquals(true, resultStory.Is_Bundle__c, 'Is bundle must be True');
            System.assertEquals('Utility', resultStory.RecordType.Name, 'Record type must be Utility');
            System.assertEquals(story.User_Story_Title__c, resultStory.User_Story_Title__c, 'Title is not correct');
            System.assertEquals(story.Project__c, resultStory.Project__c, 'Project is not correct');
            System.assertEquals(story.Org_Credential__c, resultStory.Org_Credential__c, 'Org Credential is not correct');
            System.assertEquals(story.Environment__c, resultStory.Environment__c, 'Environment is not correct');

            Artifact_Version__c resultBundle = [
                SELECT
                    Id,
                    User_Story__c,
                    Status__c,
                    (SELECT User_Story__c, User_Story__r.Stop_Indexing_Metadata__c, User_Story__r.Exclude_From_CBM__c FROM Bundled_Stories__r)
                FROM Artifact_Version__c
                WHERE Id = :bundle.Id
            ];
            System.assertEquals(4, resultBundle.Bundled_Stories__r.size(), 'Size of of bundles stories is not correct');
            for (Bundled_Story__c item : resultBundle.Bundled_Stories__r) {
                System.assertEquals(true, item.User_Story__r.Stop_Indexing_Metadata__c, 'This field should be true');
                System.assertEquals(true, item.User_Story__r.Exclude_From_CBM__c, 'This field should be true');
            }
            System.assertEquals(resultBundle.User_Story__c, resultStory.Id, 'User Story in Bundle is not correct');
            System.assertEquals('Locked', resultBundle.Status__c, 'Status must be Locked');

            Set<Id> chidrenIds = new Set<Id>();
            for (Bundled_Story__c record : resultBundle.Bundled_Stories__r) {
                chidrenIds.add(record.User_Story__c);
            }
            Map<Id, Deployment_Task__c> deploymentTasks = new Map<Id, Deployment_Task__c>(new DeploymentTasksSelector().byStories(chidrenIds));
            Map<Id, Deployment_Task__c> resultDeploymentTasks = new Map<Id, Deployment_Task__c>(
                new DeploymentTasksSelector().byStories(new Set<Id>{ resultStory.Id })
            );

            List<Attachment> fromChildren = new AttachmentsSelector().byParentId(deploymentTasks.keySet());
            List<Attachment> fromResult = new AttachmentsSelector().byParentId(resultDeploymentTasks.keyset());
            List<Attachment> testClassAttachment = new AttachmentsSelector()
                .byParentIdAndName(new Set<Id>{ resultStory.Id }, new Set<String>{ 'Test Classes' });

            System.assertEquals(deploymentTasks.size(), resultDeploymentTasks.size(), 'Lists no match');
            System.assertEquals(fromChildren.size(), fromResult.size(), 'Lists no match');
            System.assertEquals(1, testClassAttachment.size(), 'Test classes not present.');
        }
    }

    @IsTest
    private static void testEnvironmentConsistency() {
        System.runAs(getUser()) {
            // Setup
            String result;

            User_Story__c story = createBundleStory();
            story.Environment__c = null;

            // Exercise
            Test.startTest();
            try {
                LockBundleCtrl.lockBundle(story, getPackageVersionByName('My_Bundle').Id);
            } catch (Exception ex) {
                result = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.USB_WARNING_DIFFERENT_ENVIRONMENTS, result, 'Messages does not match');
        }
    }

    @IsTest
    private static void testPipelineConsistency() {
        System.runAs(getUser()) {
            // Setup
            String result;

            Project__c project = new Project__c(Name = 'MyProject 2');
            insert project;

            User_Story__c story = createBundleStory();
            story.Project__c = project.Id;

            // Exercise
            Test.startTest();
            try {
                LockBundleCtrl.lockBundle(story, getPackageVersionByName('My_Bundle').Id);
            } catch (Exception ex) {
                result = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.USB_WARNING_DIFFERENT_PIPELINES, result, 'Messages does not match');
        }
    }

    @IsTest
    private static void testGetFieldsFieldset() {
        System.runAs(getUser()) {
            // Exercise
            List<String> result = LockBundleCtrl.getFieldsFromFieldSet(SObjectType.User_Story__c.getName(), Settings.ns + 'Bundle');

            // Verify
            List<FieldSetMember> fields = Schema.SObjectType.User_Story__c.fieldSets.getMap().get(Settings.ns + 'Bundle').getFields();
            System.assertEquals(fields.size(), result.size());
        }
    }

    @IsTest
    private static void getLockedChildStories() {
        System.runAs(getUser()) {
            // Setup
            Artifact_Version__c lockedVersion = getPackageVersionByName('My_Bundle');
            lockedVersion.Name = 'Locked_Bundle';
            lockedVersion.Status__c = 'Locked';
            update lockedVersion;
            createTestBundle();
            Artifact_Version__c newVersion = getPackageVersionByName('My_Bundle');

            // Exercise
            Test.startTest();
            List<String> lockedStories = LockBundleCtrl.getLockedChildStories(newVersion.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(4, lockedStories.size());
        }
    }

    @IsTest
    private static void getPrefilledStory() {
        System.runAs(getUser()) {
            // Setup
            Artifact_Version__c version = getPackageVersionByName('My_Bundle');
            User_Story__c us = fetchStoriesByRecordType('User_Story').get(0);

            // Exercise
            User_Story__c result = LockBundleCtrl.createPrefilledStory(version.Id);

            // Verify
            System.assertEquals(version.Name, result.User_Story_Title__c);
            System.assertEquals(us.Project__c, result.Project__c);
            System.assertEquals(us.Release__c, result.Release__c);
            System.assertEquals(us.Org_Credential__c, result.Org_Credential__c);
            System.assertEquals(us.Environment__c, result.Environment__c);
        }
    }

    @IsTest
    private static void getPrefilledStoryWithDefaultCredential() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c us = fetchStoriesByRecordType('User_Story').get(0);
            Org__c o = TestDataFactory.createOrgCredentials('dev2@testOrg.com', us.Environment__c, 'Production/Developer');
            o.Default_Credential__c = true;
            insert o;

            // Exercise
            Test.startTest();
            us.Org_Credential__c = o.Id;
            update us;
            User_Story__c result = LockBundleCtrl.createPrefilledStory(getPackageVersionByName('My_Bundle').Id);
            Test.stopTest();

            // Verify
            System.assertEquals(o.Id, result.Org_Credential__c);
        }
    }

    @IsTest
    private static void getPrefilledStoryWithDifferentFieldValues() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c us = fetchStoriesByRecordType('User_Story').get(0);

            Project__c p = TestDataFactory.createProject('My Project 2.0', us.Project__r.Deployment_Flow__c, true);
            insert p;

            Release__c r = TestDataFactory.createRelease('My Release 2.0', p.Id);
            insert r;

            // Exercise
            Test.startTest();
            us.Project__c = p.Id;
            us.Release__c = r.Id;
            update us;
            User_Story__c result = LockBundleCtrl.createPrefilledStory(getPackageVersionByName('My_Bundle').Id);
            Test.stopTest();

            // Verify
            System.assertEquals(null, result.Project__c);
            System.assertEquals(r.Id, result.Release__c);
        }
    }

    @IsTest
    private static void getPrefilledStoryException() {
        System.runAs(getUser()) {
            // Setup
            String result;

            Artifact_Version__c version = getPackageVersionByName('My_Bundle');
            delete version;

            // Exercise
            try {
                LockBundleCtrl.createPrefilledStory(version.Id);
            } catch (Exception ex) {
                result = ex.getMessage();
            }

            // Verify
            System.assert(String.isNotBlank(result));
        }
    }

    @IsTest
    private static void missingGitSnapshot() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c story = createBundleStory();

            // Exercise
            Test.startTest();
            Git_Backup__c s = [SELECT Id, Git_Snapshot_Permissions__c FROM Git_Backup__c WHERE Org__c = :story.Org_Credential__c LIMIT 1];
            s.Git_Snapshot_Permissions__c = 'Allow Snapshots Only';
            update s;
            try {
                LockBundleCtrl.lockBundle(story, getPackageVersionByName('My_Bundle').Id);
            } catch (Exception ex) {
                // Verify
                System.assertEquals(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND, ex.getMessage(), 'Messages does not match');
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void emailForLockBundleFailure() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c story = createBundleStory();
            String error = 'Error occurred';

            // Exercise
            Test.startTest();
            CloneDeploymentTasks cloneDeploymentTasks = new CloneDeploymentTasks(story);
            String emailHTMLBody = cloneDeploymentTasks.getEmailTemplateBody(error);
            Test.stopTest();

            // Verify
            System.assert(emailHTMLBody.contains(error), 'The email body should contain the error message');
        }
    }

    @IsTest
    private static void cloneDeploymentTasksFailure() {
        System.runAs(getUser()) {
            // Setup
            CloneDeploymentTasks cloneDeploymentTasks = new CloneDeploymentTasks(null, null);
            Boolean exceptionOccured = false;

            // Exercise
            try {
                Test.startTest();
                System.enqueueJob(cloneDeploymentTasks);
                Test.stopTest();
            } catch (Exception e) {
                exceptionOccured = true;
            }

            // Verify
            System.assert(exceptionOccured, 'The Queueable job CloneDeploymentTasks should throw an exception');
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Username FROM User WHERE Username = 'test_user@myorg.com' LIMIT 1];
    }

    private static void createData() {
        TestUtilities.enableLicenses(10, 10, 10, 10, 10, 100);
        ITestDefaults users = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = users.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(standardUser.Username, true, true, true, true, true);

            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('Pipeline1', true, repo.Id, false);
            insert pipeline;

            Project__c project = TestDataFactory.createProject('Project1', pipeline.Id, false);
            insert project;

            Org__c credential = TestDataFactory.createOrgCredentials(1, 'bundle@org.com.test2').get(0);
            credential.SFDC_Org_ID__c = '00D1i00000095CBEAY_0050X000007h8hTQAQ';
            update credential;

            Git_Backup__c snapshot = TestDataFactory.createGitBackup('Snapshot1', credential.Id, repo.Id);
            insert snapshot;

            List<Git_Org_Commit__c> orgCommits = createGitOrgCommit(snapshot.Id, credential.Id);
            insert orgCommits;

            List<User_Story__c> stories = TestDataFactory.createUserStories(4, 'US', 'Approved', null, project.Id, null, credential.Id, 'User_Story');
            insert stories;

            List<User_Story_Commit__c> userStoryCommits = createUserStoryCommits(stories, orgCommits);
            insert userStoryCommits;

            Deployment_Task__c deploymentTask1 = new Deployment_Task__c(
                User_Story__c = stories[0].Id,
                Task_Description__c = 'Deployment Task Description',
                Type__c = 'Manual Task'
            );

            Deployment_Task__c deploymentTask2 = new Deployment_Task__c(
                User_Story__c = stories[0].Id,
                Task_Description__c = 'Deployment Task Apex',
                Type__c = 'Apex'
            );

            insert new List<Deployment_Task__c>{ deploymentTask1, deploymentTask2 };

            Attachment att1 = new Attachment(
                ParentId = orgCommits[0].Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":true}, {"t":"EmailTemplate","n":"Template2","s":false}]')
            );

            Attachment att2 = new Attachment(
                ParentId = orgCommits[1].Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":false}, {"t":"EmailTemplate","n":"a_Template","s":true}]')
            );

            Attachment fullProfiles = new Attachment(
                ParentId = orgCommits[2].Id,
                Name = 'Metadata',
                Body = Blob.valueOf('[{"t":"PermissionSet","n":"Charly_Permission"}]')
            );

            Attachment destructive = new Attachment(
                ParentId = orgCommits[3].Id,
                Name = 'Git Deletion',
                Body = Blob.valueOf('[{"n":"Hi","s":true,"b":"","cb":"","r":false,"t":"ApexClass"}]')
            );

            Attachment testOnlyAttachment = new Attachment(
                ParentId = stories[0].Id,
                Name = 'Test Classes',
                Body = Blob.valueOf('[{"n":"test_class","s":true,"r":false,"ns":""}]')
            );

            Attachment testApexDeploymentTask = new Attachment(
                ParentId = deploymentTask1.Id,
                Name = 'Apex',
                Body = Blob.valueOf('System.debug(\'debug\')')
            );

            insert new List<Attachment>{ att1, att2, fullProfiles, destructive, testOnlyAttachment, testApexDeploymentTask };
            createTestBundle();
        }
    }

    private static Artifact_Version__c getPackageVersionByName(String name) {
        return [SELECT Id, Name, Status__c FROM Artifact_Version__c WHERE Name = :name LIMIT 1];
    }

    private static List<User_Story__c> fetchStoriesByRecordType(String developerName) {
        return [
            SELECT Id, Project__c, Release__c, Org_Credential__c, Environment__c, Project__r.Deployment_Flow__c
            FROM User_Story__c
            WHERE RecordType.DeveloperName = :developerName
        ];
    }

    private static User_Story__c createBundleStory() {
        Org__c credential = [SELECT Id, Environment__c FROM Org__c WHERE Username__c = 'bundle@org.com.test20' LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Project1' LIMIT 1];
        User_Story__c story = TestDataFactory.createUserStories(
                1,
                'My Parent Story',
                'Approved',
                null,
                project.Id,
                credential.Environment__c,
                credential.Id,
                'Utility'
            )
            .get(0);
        story.Is_Bundle__c = true;

        return story;
    }

    private static List<Git_Org_Commit__c> createGitOrgCommit(Id snapshot, Id orgId) {
        Git_Org_Commit__c c1 = TestDataFactory.createGitOrgCommit('Bundle Metadata', Date.today(), snapshot, orgId, 'Complete');
        c1.Git_Operation__c = 'Commit Files';

        Git_Org_Commit__c c2 = TestDataFactory.createGitOrgCommit('Bundle Metadata2', Date.today(), snapshot, orgId, 'Complete');
        c2.Git_Operation__c = 'Commit Files';

        Git_Org_Commit__c c3 = TestDataFactory.createGitOrgCommit('Bundle Profiles', Date.today(), snapshot, orgId, 'Complete');
        c3.Git_Operation__c = 'Full Profiles & Permission Sets';

        Git_Org_Commit__c c4 = TestDataFactory.createGitOrgCommit('Bundle Destructive', Date.today(), snapshot, orgId, 'Complete');
        c4.Git_Operation__c = 'Destructive Changes';

        return new List<Git_Org_Commit__c>{ c1, c2, c3, c4 };
    }

    private static List<User_Story_Commit__c> createUserStoryCommits(List<User_Story__c> stories, List<Git_Org_Commit__c> orgCommits) {
        List<User_Story_Commit__c> userStoryCommits = new List<User_Story_Commit__c>();

        for (Integer i = 0; i < 4; i++) {
            User_Story_Commit__c usc = new User_Story_Commit__c(User_Story__c = stories[i].Id, Snapshot_Commit__c = orgCommits[i].Id);
            userStoryCommits.add(usc);
        }

        return userStoryCommits;
    }

    private static void createTestBundle() {
        Map<Id, User_Story__c> selectedUserStories = new Map<Id, User_Story__c>(
            [
                SELECT Id, Name, Environment__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Platform__c
                FROM User_Story__c
                LIMIT 4
            ]
        );
        Artifact__c parentBundle = new Artifact__c(
            Name = 'My_Bundle',
            RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId()
        );
        insert parentBundle;
        Artifact_Version__c bundle = new Artifact_Version__c(Name = 'My_Bundle', Artifact__c = parentBundle.Id);

        UserStoryBundleCtrl.createBundleRecords(bundle, selectedUserStories.values(), testMetadata(), testFullProfiles(), testDestructive());
    }

    private static List<MetaDataItem> testMetadata() {
        MetaDataItem item = new MetaDataItem();
        item.n = 'Template1';
        item.r = false;
        item.s = true;
        item.t = 'EmailTemplate';

        MetaDataItem item2 = new MetaDataItem();
        item2.n = 'Template2';
        item2.s = true;
        item2.t = 'EmailTemplate';

        MetaDataItem item3 = new MetaDataItem();
        item3.n = 'a_Template';
        item3.s = true;
        item3.t = 'EmailTemplate';

        return new List<MetaDataItem>{ item, item2, item3 };
    }

    private static List<MetaDataItem> testFullProfiles() {
        MetaDataItem item = new MetaDataItem();
        item.n = 'Charly_Permission';
        item.s = true;
        item.t = 'PermissionSet';

        return new List<MetaDataItem>{ item };
    }

    private static List<MetaDataItem> testDestructive() {
        MetaDataItem item = new MetaDataItem();
        item.n = 'Hi';
        item.r = false;
        item.s = true;
        item.t = 'ApexClass';
        item.cb = '';

        return new List<MetaDataItem>{ item };
    }
}