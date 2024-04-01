@IsTest
public class PerformUserStoryActionTest {
    @TestSetup
    static void testSetup() {
        createData();
    }

    @IsTest
    private static void performAction() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_story__c s = [SELECT Id FROM User_Story__c WHERE Is_Bundle__c = TRUE AND RecordType.DeveloperName = 'Utility' LIMIT 1];
            Git_Org_Commit__c c = [SELECT Id, Git_Backup__c FROM Git_Org_Commit__c LIMIT 1];

            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Exercise
            Test.startTest();
            PerformUserStoryAction.startActionFlow(s.Id, new List<Id>{ c.Id }, c.Git_Backup__c, 'commit');
            Test.stopTest();

            // Verify
            FlowInterview f = [SELECT CurrentElement, InterviewLabel FROM FlowInterview WHERE InterviewStatus = 'Paused' LIMIT 1];
            System.assertEquals('WaitForEvent', f.CurrentElement);
            System.assert(f.InterviewLabel.startsWith('Perform User Story Actions'));
            System.assertEquals(0, Limits.getEmailInvocations());
        }
    }

    @IsTest
    private static void fetchCommits() {
        System.runAs(getRunAsUser()) {
            // Setup
            Git_Org_Commit__c c = [SELECT Id FROM Git_Org_Commit__c LIMIT 1];

            // Exercise
            List<Git_Org_Commit__c> commits = PerformUserStoryAction.fetchCommits(new List<Id>{ c.Id });

            // Verify
            System.assertEquals(1, commits?.size());
        }
    }

    @IsTest
    private static void exception() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_story__c s = [SELECT Id FROM User_Story__c WHERE Is_Bundle__c = TRUE AND RecordType.DeveloperName = 'Utility' LIMIT 1];
            // Note: To provoke exception and subsequently send email alert
            delete [SELECT Id, Git_Backup__c, Commit_Message__c FROM Git_Org_Commit__c LIMIT 1];

            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Exercise
            new PerformUserStoryCallout(s.Id, null, 'commit').execute(null);

            // Verify
            System.assertEquals(1, Limits.getEmailInvocations());
        }
    }

    // HELPER

    private static void createData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);

        TestDataFactory.createUsers();
        User u = getRunAsUser();

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

        System.runAs(u) {
            TestUtilities.assignLicense(u.Username, true, true, true, true, true);
            setup();
            bundlingJob();
        }
    }

    private static void setup() {
        Org__c o = TestDataFactory.createOrgCredentials(1, 'bundle@org.com.test').get(0);
        o.SFDC_Org_ID__c = '00D1i00000095cEEAQ_0050X000007h8hTQAQ';
        update o;

        Environment__c e = [SELECT Id FROM Environment__c LIMIT 1];

        Git_Repository__c r = TestDataFactory.createGitRepository();
        insert r;

        Deployment_Flow__c pp = TestDataFactory.createDeploymentFlow('Pipeline1', true, r.Id, false);
        insert pp;

        Project__c prj = TestDataFactory.createProject('Project1', pp.Id, false);
        insert prj;

        Git_Backup__c s = TestDataFactory.createGitBackup('Snapshot1', o.Id, r.Id);
        insert s;

        Git_Org_Commit__c c = TestDataFactory.createGitOrgCommit('commit1', Date.today(), s.Id, o.Id, 'Complete');
        c.Git_Operation__c = 'Commit Files';
        c.Commit_Message__c = 'US1: US1 Bundle Metadata';
        insert c;

        List<User_Story__c> us = TestDataFactory.createUserStories(2, 'US', 'Approved', null, prj.Id, e.Id, o.Id, 'User_Story');
        insert us;
    }

    private static void bundlingJob() {
        List<Artifact__c> p = TestDataFactory.createPackages(1, 'pkg', 'User_Story_Bundle');
        insert p;

        List<Artifact_Version__c> v = TestDataFactory.createPackageVersions(1, 'pkgVersion', p.get(0).Id);
        insert v;

        List<User_Story__c> s = [
            SELECT Id, Environment__c, Project__c, Org_Credential__c
            FROM User_Story__c
            WHERE RecordType.DeveloperName = 'User_Story'
        ];
        List<Bundled_Story__c> bundled = TestDataFactory.createBundledStories(v.get(0).Id, s);
        insert bundled;

        List<User_Story__c> bs = TestDataFactory.createUserStories(
            1,
            'USB',
            'Approved',
            null,
            s[0].Project__c,
            s[0].Environment__c,
            s[0].Org_Credential__c,
            'Utility'
        );
        bs.get(0).Is_Bundle__c = true;
        insert bs;

        v.get(0).User_Story__c = bs.get(0).Id;
        update v;
    }

    private static User getRunAsUser() {
        return [SELECT Id, Username FROM User WHERE Email = 'test2@test2.com' LIMIT 1];
    }
}