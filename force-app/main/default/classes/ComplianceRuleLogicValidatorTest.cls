@isTest
private with sharing class ComplianceRuleLogicValidatorTest {
    @TestSetup
    private static void setupData() {
        insertData();
    }

    @isTest
    private static void executeSuccessfully() {
        System.runAs(getTestUser()) {
            // Setup
            String criteriaLogic = '1 AND (2 OR 3)';
            List<Compliance_Rule_Criteria__c> criterias = getTestCriterias();

            // Exercise
            ValidationResult result = new ComplianceRuleLogicValidator(criteriaLogic, criterias).execute();

            // Verify
            System.assert(!result.isError(), 'Criteria Logic validation should be successful');
        }
    }

    @isTest
    private static void failsIfExtraBracket() {
        System.runAs(getTestUser()) {
            // Setup
            String criteriaLogic = '1 AND ((2 OR 3)';
            List<Compliance_Rule_Criteria__c> criterias = getTestCriterias();

            // Exercise
            ValidationResult result = new ComplianceRuleLogicValidator(criteriaLogic, criterias).execute();

            // Verify
            System.assert(result.isError(), 'Criteria Logic validation should not be successful');
            System.assertEquals(Label.CCH_NONVALID_CRITERIA_LOGIC_SYNTAX, result.toString(), 'Expected: ' + Label.CCH_NONVALID_CRITERIA_LOGIC_SYNTAX);
        }
    }

    @isTest
    private static void failsIfWrongToken() {
        System.runAs(getTestUser()) {
            // Setup
            String criteriaLogic = '1 ANDD (2 OR 3)';
            List<Compliance_Rule_Criteria__c> criterias = getTestCriterias();

            // Exercise
            ValidationResult result = new ComplianceRuleLogicValidator(criteriaLogic, criterias).execute();

            // Verify
            System.assert(result.isError(), 'Criteria Logic validation should not be successful');
            System.assertEquals(Label.CCH_NONVALID_CRITERIA_LOGIC_SYNTAX, result.toString(), 'Expected: ' + Label.CCH_NONVALID_CRITERIA_LOGIC_SYNTAX);
        }
    }

    @isTest
    private static void failsWhenMissingCriteriaReference() {
        System.runAs(getTestUser()) {
            // Setup
            String criteriaLogic = '1 AND 2';
            List<Compliance_Rule_Criteria__c> criterias = getTestCriterias();

            // Exercise
            ValidationResult result = new ComplianceRuleLogicValidator(criteriaLogic, criterias).execute();

            // Verify
            System.assert(result.isError(), 'Criteria Logic validation should not be successful');
            System.assertEquals(Label.CCH_NONVALID_CRITERIA_LOGIC_REFERENCES, result.toString(), 'Expected: ' + Label.CCH_NONVALID_CRITERIA_LOGIC_REFERENCES);
        }
    }

    @isTest
    private static void failsWhenMissingThereAreExtraReferences() {
        System.runAs(getTestUser()) {
            // Setup
            String criteriaLogic = '1 AND 2 AND 3 AND 4';
            List<Compliance_Rule_Criteria__c> criterias = getTestCriterias();

            // Exercise
            ValidationResult result = new ComplianceRuleLogicValidator(criteriaLogic, criterias).execute();

            // Verify
            System.assert(result.isError(), 'Criteria Logic validation should not be successful');
            System.assertEquals(Label.CCH_NONVALID_CRITERIA_LOGIC_REFERENCES, result.toString(), 'Expected: ' + Label.CCH_NONVALID_CRITERIA_LOGIC_REFERENCES);
            
        }
    }

    @isTest
    private static void failsWhenCriteriaReferencesMismatch() {
        System.runAs(getTestUser()) {
            // Setup
            String criteriaLogic = '1 AND (2 OR 4)';
            List<Compliance_Rule_Criteria__c> criterias = getTestCriterias();

            // Exercise
            ValidationResult result = new ComplianceRuleLogicValidator(criteriaLogic, criterias).execute();

            // Verify
            System.assert(result.isError(), 'Criteria Logic validation should not be successful');
            System.assertEquals(Label.CCH_NONVALID_CRITERIA_LOGIC_REFERENCES, result.toString(), 'Expected: ' + Label.CCH_NONVALID_CRITERIA_LOGIC_REFERENCES);
        }
    }

    private static void insertData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);

            String testRuleName = 'testRule';
            String testNode = 'testNode';
            String testField = 'testField';
            String testOperator = 'equals';
            String testValue = 'testValue';

            Compliance_Rule__c rule = TestDataFactory.createComplianceRule(testRuleName);
            insert rule;

            Compliance_Rule_Criteria__c criteria1 = TestDataFactory.newCriteria(rule.Id, testNode, testField, testOperator, testValue, 1);
            Compliance_Rule_Criteria__c criteria2 = TestDataFactory.newCriteria(rule.Id, testNode, testField, testOperator, testValue, 2);
            Compliance_Rule_Criteria__c criteria3 = TestDataFactory.newCriteria(rule.Id, testNode, testField, testOperator, testValue, 3);
            insert new List<Compliance_Rule_Criteria__c>{ criteria1, criteria2, criteria3 };
        }
    }

    private static List<Compliance_Rule_Criteria__c> getTestCriterias() {
        return [SELECT Order__c FROM Compliance_Rule_Criteria__c];
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];

        return standardUser;
    }

    private static User getTestUser() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        return testUser;
    }

}