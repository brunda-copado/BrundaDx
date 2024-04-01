@isTest
private class ManualTestsAcceptanceCriteriaCtrlTest {
    private static final String SMALL_SAMPLE_CRITERIA = '[{"testerScope":"Group","tester":{"icon":"standard:groups","id":"00G09000003gbdNEAQ","sObjectType":"Group","subtitle":"Group • Test","title":"Test","titleFormatted":"Test","subtitleFormatted":"Group • Test"},"type":"Required","minimumTesters":"2","editableTesters":true}]';
    private static final String SAMPLE_CRITERIA = '[{"testerScope":"Group","tester":{"icon":"standard:groups","id":"00G09000003gbdNEAQ","sObjectType":"Group","subtitle":"Group • Test","title":"Test","titleFormatted":"Test","subtitleFormatted":"Group • Test"},"type":"Required","minimumTesters":"2","editableTesters":true},{"testerScope":"User","tester":{"icon":"standard:user","id":"0050900000299hdAAA","sObjectType":"User","subtitle":"User • Manuel Moya","title":"Manuel Moya","titleFormatted":"<strong>Man</strong>uel Moya","subtitleFormatted":"User • <strong>Man</strong>uel Moya"},"type":"Optional","minimumTesters":1,"editableTesters":false}]';

    @isTest
    private static void executeUpdateExtensionConfig() {
        System.runAs(getRunAsUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = [SELECT Id FROM ExtensionConfiguration__c];

            // Exercise
            ManualTestsAcceptanceCriteriaCtrl.storeAcceptanceCriteria(SAMPLE_CRITERIA, extensionConfiguration.id);

            // Verify
            System.assertEquals(
                SAMPLE_CRITERIA,
                [SELECT AcceptanceCriteria__c FROM ExtensionConfiguration__c]
                .AcceptanceCriteria__c,
                'Acceptance Criteria should be updated.'
            );
        }
    }

    @isTest
    private static void executeUpdateTest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Test__c test = [SELECT Id FROM Test__c];

            // Exercise
            ManualTestsAcceptanceCriteriaCtrl.storeAcceptanceCriteria(SAMPLE_CRITERIA, test.id);

            // Verify
            System.assertEquals(
                SAMPLE_CRITERIA,
                [SELECT AcceptanceCriteria__c FROM Test__c]
                .AcceptanceCriteria__c,
                'Acceptance Criteria should be updated.'
            );
        }
    }

    @isTest
    private static void executeUpdateQgrc() {
        System.runAs(getRunAsUser()) {
            // Setup
            Quality_Gate_Rule_Condition__c condition = qualityGateRuleCondition();
            QualityGateRuleConditionsSelector.setMock(new List<Quality_Gate_Rule_Condition__c>{ condition });

            // Exercise
            ManualTestsAcceptanceCriteriaCtrl.storeAcceptanceCriteria(SAMPLE_CRITERIA, condition.id);

            // Verify
            System.assertEquals(SAMPLE_CRITERIA, condition.AcceptanceCriteria__c, 'Acceptance Criteria should be updated.');
        }
    }

    @isTest
    private static void fetchQgrcAcceptanceCriteria() {
        System.runAs(getRunAsUser()) {
            // Setup
            Quality_Gate_Rule_Condition__c condition = qualityGateRuleCondition();
            QualityGateRuleConditionsSelector.setMock(new List<Quality_Gate_Rule_Condition__c>{ condition });

            // Exercise
            String acceptanceCriteria = ManualTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(condition.id);

            // Verify
            System.assertEquals(condition.AcceptanceCriteria__c, acceptanceCriteria, 'Acceptance Criteria should be the same.');
        }
    }

    @isTest
    private static void fetchExtConfigAcceptanceCriteria() {
        System.runAs(getRunAsUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = [SELECT Id, AcceptanceCriteria__c FROM ExtensionConfiguration__c];

            // Exercise
            ManualTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(extensionConfiguration.id);

            // Verify
            System.assertEquals(SMALL_SAMPLE_CRITERIA, extensionConfiguration.AcceptanceCriteria__c, 'Acceptance Criteria should be the same.');
        }
    }

    @isTest
    private static void fetchTestAcceptanceCriteria() {
        System.runAs(getRunAsUser()) {
            // Setup
            Test__c test = [SELECT Id, AcceptanceCriteria__c FROM Test__c];

            // Exercise
            ManualTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(test.id);

            // Verify
            System.assertEquals(SMALL_SAMPLE_CRITERIA, test.AcceptanceCriteria__c, 'Acceptance Criteria should be the same.');
        }
    }

    @isTest
    private static void fetchTestAcceptanceCriteriaWithNoRecordID() {
        System.runAs(getRunAsUser()) {
            // Exercise
            String acceptanceCriteria = ManualTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(null);

            // Verify
            System.assertEquals('{}', acceptanceCriteria, 'Acceptance criteria should be {}.');
        }
    }

    @isTest
    private static void getRecentlyViewedUsers() {
        System.runAs(getRunAsUser()) {
            // Setup
            ManualTestsAcceptanceCriteriaCtrl.mockUsers = new List<User>{ getRunAsUser() };

            // Exercise
            List<LookupSearchResult> recentlyViewedUsers = ManualTestsAcceptanceCriteriaCtrl.getRecentlyViewedUsers();

            // Verify
            System.assertEquals(1, recentlyViewedUsers.size(), 'List should have 1 user');
            System.assertEquals('John Doe', recentlyViewedUsers[0].getTitle(), 'Title should be John Doe');
            System.assertEquals('User • John Doe', recentlyViewedUsers[0].getSubtitle(), 'Subtitle should be User • John Doe');
            System.assertEquals(getRunAsUser().Id, recentlyViewedUsers[0].getId(), 'User Id should match');
            System.assertEquals('standard:user', recentlyViewedUsers[0].getIcon(), 'Icon should be standard:user');
            System.assertEquals('User', recentlyViewedUsers[0].getSObjectType(), 'sObjectType should be User');
        }
    }

    @isTest
    private static void getRecentlyModifiedGroups() {
        System.runAs(getRunAsUser()) {
            // Exercise
            List<LookupSearchResult> recentlyModifiedGroups = ManualTestsAcceptanceCriteriaCtrl.getRecentlyModifiedGroups();

            // Verify
            System.assertEquals(1, recentlyModifiedGroups.size(), 'List should have 1 group');
            System.assertEquals('Mock Group', recentlyModifiedGroups[0].getTitle(), 'Title should be Mock Group');
            System.assertEquals('Group • Mock Group', recentlyModifiedGroups[0].getSubtitle(), 'Subtitle should be Group • Mock Group');
            System.assertEquals(null, recentlyModifiedGroups[0].getId(), 'Group Id should match');
            System.assertEquals('standard:groups', recentlyModifiedGroups[0].getIcon(), 'Icon should be standard:groups');
            System.assertEquals('Group', recentlyModifiedGroups[0].getSObjectType(), 'sObjectType should be Group');
        }
    }

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    private static User getRunAsUser() {
        return [SELECT Name FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        ExtensionConfiguration__c extensionConfiguration = new ExtensionConfiguration__c(
            Active__c = true,
            ExtensionTool__c = 'Manual Tests',
            ExtensionApplication__c = 'Test',
            AcceptanceCriteria__c = SMALL_SAMPLE_CRITERIA
        );
        insert extensionConfiguration;

        User_Story__c userStory = new User_Story__c(Minimum_Apex_Code_Coverage__c = 75);
        insert userStory;

        Test__c testItem = new Test__c(ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory.Id);
        insert testItem;
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1].id;
    }

    private static Quality_Gate_Rule_Condition__c qualityGateRuleCondition() {
        Quality_Gate_Rule_Condition__c condition = new Quality_Gate_Rule_Condition__c(
            Extension_Configuration__c = getExtensionConfigurationId(),
            Platform__c = 'Other',
            AcceptanceCriteria__c = SAMPLE_CRITERIA
        );

        return condition;
    }
}