@IsTest
private class ActionTemplateTest {

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void getApiNameWithJobTemplate() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStory();

            // Exercise
            Test.startTest();
            String result = new ActionTemplate('Commit').userStory(userStory).getApiName();
            Test.stopTest();

            // Verify
            System.assertEquals('Commit_Template_1', result, 'Template Name should match');
        }
    }

    @IsTest
    private static void getApiNameWithoutJobTemplate() {
        System.runAs(getRunAsUser()) {
            // Setup
            delete [SELECT Id FROM JobStep__c];
            delete [SELECT Id FROM JobTemplate__c];

            User_Story__c userStory = getUserStory();
            String templateName;
            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                templateName = new ActionTemplate('Commit').userStory(userStory).getApiName();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assert(expectedException.getMessage().contains(Label.Error_No_Action_Template_Defined), 'Exception message should match: ' + expectedException.getMessage());
        }
    }

    private static void createData() {
        new JobTemplate().name('Commit_Template').mockAutomation('Commit').add(new JobStep()).persist();
        Credential source = new Credential();
        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(new Environment().name('dev1').platform('Other').add(source), new Environment().platform('Other').add(new Credential()))
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

    private static User_Story__c getUserStory() {
        return [
            SELECT Id,
                Environment__c,
                Release__r.Base_Branch__c,
                Project__r.Deployment_Flow__r.Main_Branch__c,
                Project__r.Deployment_Flow__c,
                Project__r.Deployment_Flow__r.Git_Repository__c,
                Release__r.Project__r.Deployment_Flow__c,
                Release__r.Project__c,
                US_Feature__r.Application__c,
                Org_Credential__r.Validated_Date__c,
                Sprint__r.Start_Date__c
            FROM User_Story__c
            LIMIT 1
        ];
    }
}