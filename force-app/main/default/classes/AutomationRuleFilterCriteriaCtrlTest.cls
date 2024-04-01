@IsTest
@SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
private with sharing class AutomationRuleFilterCriteriaCtrlTest {
    @TestSetup
    private static void makeData() {
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void checkSyntax() {
        // Setup
        System.runAs(getUser()) {
            // Setup
            String objectName = User_Story__c.SObjectType.getDescribe().getName();
            String whereCondition = 'User_Story_Title__c = \'US1\'';

            // Exercise
            Test.startTest();
            AutomationRuleFilterCriteriaCtrl.SyntaxResponse response = AutomationRuleFilterCriteriaCtrl.checkSyntax(objectName, whereCondition);
            Test.stopTest();

            // Verify
            System.assertEquals(true, response.isValid, 'Where condition should be marked as valid');
        }
    }

    @IsTest
    private static void checkSyntaxInvalid() {
        // Setup
        System.runAs(getUser()) {
            // Setup
            String objectName = User_Story__c.SObjectType.getDescribe().getName();
            String whereCondition = 'User_Story_Title__c > NULL';

            // Exercise
            Test.startTest();
            AutomationRuleFilterCriteriaCtrl.SyntaxResponse response = AutomationRuleFilterCriteriaCtrl.checkSyntax(objectName, whereCondition);
            Test.stopTest();

            // Verify
            System.assertEquals(false, response.isValid, 'Where condition should be marked as invalid');
        }
    }

    private static void createData() {
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
                    .add(new UserStory().title('US1').credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US2').credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}