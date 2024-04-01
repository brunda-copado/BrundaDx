@IsTest
public class PromoteBundledChildStoriesTest {
    
    @TestSetup
    static void testSetup() {
        createData();
    }

    @IsTest
    private static void onCompletedPromotion() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            System.enqueueJob(new PromoteBundledChildStories(new Set<Id>{ fetchPromotion().Id }));
            Test.stopTest();
        }

        // Verify
        User_Story__c bundleStory = fetchBundleStory();
        User_Story__c childStory = fetchChildStory().get(0);
        System.assertEquals(bundleStory.Environment__c, childStory.Environment__c, 'Environments should be same.');

        List<Promoted_User_Story__c> childJunction = fetchJunction(childStory.Id);
        List<Promoted_User_Story__c> parentJunction = fetchJunction(bundleStory.Id);
        System.assertEquals(1, childJunction.size(), 'Child Bundled Stories should be promoted');
        System.assertNotEquals(childJunction[0].Id, parentJunction[0].Id, 'Child Bundled Stories should be promoted seperately');
        System.assertEquals('Completed', parentJunction[0].Promotion__r.Status__c);
    }

    @IsTest
    private static void onNonCompletedPromotion() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c p = fetchPromotion();
            p.Status__c = 'Draft';
            update p;

            // Exercise
            Test.startTest();
            System.enqueueJob(new PromoteBundledChildStories(new Set<Id>{ fetchPromotion().Id }));
            Test.stopTest();
        }

        // Verify
        List<Promoted_User_Story__c> childJunction = fetchJunction(fetchChildStory().get(0).Id);
        System.assertEquals(0, childJunction.size(), 'Child Bundled Stories should not be promoted');
    }

    @IsTest
    private static void failure() {
        System.runAs(getRunAsUser()) {
            // Setup
            // Note: To provoke the exception in queueable apex
            delete [SELECT Id FROM Bundled_Story__c];

            // Exercise
            Test.startTest();
            System.enqueueJob(new PromoteBundledChildStories(new Set<Id>{ fetchPromotion().Id }));
            Test.stopTest();
        }

        // Verify
        User_Story__c bundleStory = fetchBundleStory();
        User_Story__c childStory = fetchChildStory().get(0);
        System.assertEquals(bundleStory.Environment__c, childStory.Environment__c, 'Environments should be different.');

        List<Promoted_User_Story__c> junction = fetchJunction(childStory.Id);
        System.assert(junction.isEmpty(), 'Child Bundled Stories should not be promoted');
    }

    // HELPER

    private static void createData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);

        TestDataFactory.createUsers();
        User copadoUser = getRunAsUser();

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = copadoUser.Id, PermissionSetId = ps.Id);

        System.runAs(copadoUser) {
            TestUtilities.assignLicense(copadoUser.Username, true, true, true, true, true);
            setup();
            bundlingJob();
            promotionJob();
        }
    }

    private static void setup() {
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(2, 'bundle@org.com.test');
        orgs[0].SFDC_Org_ID__c = '00D1i00000095cEEAQ_0050X000007h8hTQAQ';
        orgs[1].SFDC_Org_ID__c = '00D1i00000095cEEAP_0050X000007h8hTQAP';
        update orgs;

        List<Org__c> orgCred = [SELECT Id, Environment__c FROM Org__c WHERE ID IN :orgs];

        Git_Repository__c repo = TestDataFactory.createGitRepository();
        insert repo;

        Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('Test Pipeline', true, repo.Id, false);
        insert pipeline;

        Deployment_Flow_Step__c pipelineConnection = TestDataFactory.createDeploymentFlowStep(
            orgCred[0].Environment__c,
            orgCred[1].Environment__c,
            pipeline.Id,
            ''
        );
        insert pipelineConnection;

        Project__c project = TestDataFactory.createProject('test project', pipeline.Id, false);
        insert project;

        Git_Backup__c snapshot1 = TestDataFactory.createGitBackup('SnapShot1', orgCred[0].Id, repo.Id);
        insert snapshot1;

        List<User_Story__c> userStories = TestDataFactory.createUserStories(
            2,
            'US',
            'Approved',
            null,
            project.Id,
            orgCred[0].Environment__c,
            orgCred[0].Id,
            'User_Story'
        );
        insert userStories;

        Promotion__c promotion = TestDataFactory.createPromotion(
            project.Id,
            orgCred[0].Id,
            orgCred[0].Environment__c,
            orgCred[1].Id,
            orgCred[1].Environment__c,
            'Completed'
        );
        insert promotion;
    }

    private static void bundlingJob() {
        List<Artifact__c> pkg = TestDataFactory.createPackages(1, 'pkg', 'User_Story_Bundle');
        insert pkg;

        List<Artifact_Version__c> version = TestDataFactory.createPackageVersions(1, 'pkgVersion', pkg.get(0).Id);
        insert version;

        List<User_Story__c> stories = fetchChildStory();
        List<Bundled_Story__c> bundledStories = TestDataFactory.createBundledStories(version.get(0).Id, stories);
        insert bundledStories;

        List<User_Story__c> bundleStory = TestDataFactory.createUserStories(
            1,
            'USB',
            'Approved',
            null,
            stories[0].Project__c,
            stories[0].Environment__c,
            stories[0].Org_Credential__c,
            'Utility'
        );
        bundleStory.get(0).Is_Bundle__c = true;
        insert bundleStory;

        version.get(0).User_Story__c = bundleStory.get(0).Id;
        update version;
    }

    private static void promotionJob() {
        Promotion__c promotion = fetchPromotion();
        User_Story__c bundleStory = fetchBundleStory();

        Promoted_User_Story__c bundlePromotion = new Promoted_User_Story__c(User_Story__c = bundleStory.Id, Promotion__c = promotion.Id);
        insert bundlePromotion;

        bundleStory.Org_Credential__c = promotion.Destination_Org_Credential__c;
        bundleStory.Environment__c = promotion.Destination_Environment__c;
        update bundleStory;
    }

    private static User getRunAsUser() {
        return [SELECT Id, Username FROM User WHERE Email = 'test2@test2.com' LIMIT 1];
    }

    private static User_Story__c fetchBundleStory() {
        return [SELECT Id, Environment__c FROM User_Story__c WHERE Is_Bundle__c = TRUE AND RecordType.DeveloperName = 'Utility' LIMIT 1];
    }

    private static List<User_Story__c> fetchChildStory() {
        return [SELECT Id, Environment__c, Project__c, Org_Credential__c FROM User_Story__c WHERE RecordType.DeveloperName = 'User_Story'];
    }

    private static Promotion__c fetchPromotion() {
        return [SELECT Id, Destination_Org_Credential__c, Destination_Environment__c FROM Promotion__c LIMIT 1];
    }

    private static List<Promoted_User_Story__c> fetchJunction(Id Story) {
        return [SELECT Id, Promotion__r.Status__c FROM Promoted_User_Story__c WHERE User_Story__c = :story];
    }
}