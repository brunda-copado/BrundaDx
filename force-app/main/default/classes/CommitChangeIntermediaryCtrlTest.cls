@isTest(seeAllData=false)
public with sharing class CommitChangeIntermediaryCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData(true);
        }
    }

    @IsTest
    static void testDefaultPageAsCommitPage() {
        System.runAs(getRunAsUser()) {
            //Setup
            Id userStoryId = getUserStory();

            //Exercise
            Test.startTest();
            String pageName = CommitChangeIntermediaryCtrl.getCommitPageNameFromSettings(userstoryId);
            Test.stopTest();

            //Verify
            System.assertEquals(pageName.contains(CommitChangeIntermediaryCtrl.DEFAULTPAGENAME), true, 'default page should be returned');
        }
    }

    @IsTest
    static void testCustomCommitPage() {
        System.runAs(getRunAsUser()) {
            //Setup

            Id userStoryId = getUserStory();
            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(
                    Extension__r = new ExtensionPackageConfiguration__mdt(Platform__c = 'Other'),
                    Key__c = CommitChangeIntermediaryCtrl.USERSTORYCOMMITPAGE,
                    Value__c = 'testpage'
                )
            };

            //Exercise
            Test.startTest();
            String pageName = CommitChangeIntermediaryCtrl.getCommitPageNameFromSettings(userstoryId);
            Test.stopTest();

            //Verify
            System.assertEquals(pageName, 'testpage', 'custom commit page');
        }
    }

    @IsTest
    static void testNullAsUserstoryId() {
        System.runAs(getRunAsUser()) {
            //Setup

            Id userStoryId = null;

            //Exercise
            Test.startTest();
            String pageName = CommitChangeIntermediaryCtrl.getCommitPageNameFromSettings(userstoryId);
            Test.stopTest();

            //Verify
            System.assertEquals(pageName.contains(CommitChangeIntermediaryCtrl.DEFAULTPAGENAME), true, 'user story miscommunication');
        }
    }

    private static Deployment_Flow__c createData(Boolean createPipelineAction) {
        if (createPipelineAction) {
            new JobTemplate().name('Commit Template').mockAutomation('Commit').add(new JobStep()).persist();
        }

        Credential source = new Credential();

        return (Deployment_Flow__c) new Pipeline()
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
            .add(new Project().add(new UserStory().credential(source)))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getUserStory() {
        return [SELECT Id, Platform__c FROM User_Story__c LIMIT 1].Id;
    }
}