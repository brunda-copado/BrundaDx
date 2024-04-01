@isTest
private with sharing class ComplianceRuleCriteriaValidatorTest {
    @TestSetup
    static void setupData() {
        setupUser();
    }

    @isTest
    private static void executeSuccessfully() {
        System.runAs(getTestUser()) {
            // Setup
            List<Compliance_Rule_Criteria__c> criterias = new List<Compliance_Rule_Criteria__c>();
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_VALUE, 1));
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_VALUE + '2', 2));

            // Exercise
            ValidationResult result = new ComplianceRuleCriteriaValidator(criterias).execute();

            // Verify
            System.assert(!result.isError(), 'Criteria validation should be successful');
        }
    }

    @isTest
    private static void failsOnEmptyList() {
        System.runAs(getTestUser()) {
            // Setup
            List<Compliance_Rule_Criteria__c> criterias = new List<Compliance_Rule_Criteria__c>();

            // Exercise
            ValidationResult result = new ComplianceRuleCriteriaValidator(criterias).execute();

            // Verify
            System.assert(result.isError(), 'Criteria validation should not be successful');
            System.assertEquals(Label.AT_LEAST_ONE_VALID_CRITERIA, result.toString(), 'Expected: ' + Label.AT_LEAST_ONE_VALID_CRITERIA);
        }
    }

    @isTest
    private static void failsOnNonvalidCriteria() {
        System.runAs(getTestUser()) {
            // Setup
            List<Compliance_Rule_Criteria__c> criterias = new List<Compliance_Rule_Criteria__c>();
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_VALUE, 1));
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_EMPTY_VALUE, 2));

            // Exercise
            ValidationResult result = new ComplianceRuleCriteriaValidator(criterias).execute();

            // Verify
            String expectedError = String.format(Label.CCH_NONVALID_CRITERIA, new List<String>{ '2' });

            System.assert(result.isError(), 'Criteria validation should not be successful');
            System.assertEquals(expectedError, result.toString(), 'Expected: ' + expectedError);
        }
    }

    @isTest
    private static void failsOnMultipleNonvalidCriteria() {
        System.runAs(getTestUser()) {
            // Setup
            List<Compliance_Rule_Criteria__c> criterias = new List<Compliance_Rule_Criteria__c>();
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_VALUE, 1));
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_EMPTY_VALUE, 2));
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_EMPTY_FIELD, TEST_OPERATOR, TEST_VALUE, 3));

            // Exercise
            ValidationResult result = new ComplianceRuleCriteriaValidator(criterias).execute();

            // Verify
            String expectedErrorRow2 = String.format(Label.CCH_NONVALID_CRITERIA, new List<String>{ '2' });
            String expectedErrorRow3 = String.format(Label.CCH_NONVALID_CRITERIA, new List<String>{ '3' });

            System.assert(result.isError(), 'Criteria validation should not be successful');
            System.assert(result.toString().contains(expectedErrorRow2), 'Expected to contain: ' + expectedErrorRow2);
            System.assert(result.toString().contains(expectedErrorRow3), 'Expected to contain: ' + expectedErrorRow3);
        }
    }

    @isTest
    private static void failsOnDuplicatedCriteria() {
        System.runAs(getTestUser()) {
            // Setup
            List<Compliance_Rule_Criteria__c> criterias = new List<Compliance_Rule_Criteria__c>();
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_VALUE, 1));
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_FIELD, TEST_OPERATOR, TEST_VALUE, 2));

            // Exercise
            ValidationResult result = new ComplianceRuleCriteriaValidator(criterias).execute();

            // Verify
            System.assert(result.isError(), 'Criteria validation should not be successful');
            System.assertEquals(Label.CCH_DUPLICATED_CRITERIA, result.toString(), 'Expected: ' + Label.AT_LEAST_ONE_VALID_CRITERIA);
        }
    }

    @isTest
    private static void failsOnIncompleteAndDuplicatedCriteria() {
        System.runAs(getTestUser()) {
            // Setup
            List<Compliance_Rule_Criteria__c> criterias = new List<Compliance_Rule_Criteria__c>();
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_EMPTY_FIELD, TEST_OPERATOR, TEST_VALUE, 1));
            criterias.add(TestDataFactory.newCriteria(TEST_NODE, TEST_EMPTY_FIELD, TEST_OPERATOR, TEST_VALUE, 2));

            // Exercise
            ValidationResult result = new ComplianceRuleCriteriaValidator(criterias).execute();

            // Verify
            String expectedErrorRow1 = String.format(Label.CCH_NONVALID_CRITERIA, new List<String>{ '1' });
            String expectedErrorRow2 = String.format(Label.CCH_NONVALID_CRITERIA, new List<String>{ '2' });

            System.assert(result.isError(), 'Criteria validation should not be successful');
            System.assert(result.toString().contains(expectedErrorRow1), 'Expected to contain: ' + expectedErrorRow1);
            System.assert(result.toString().contains(expectedErrorRow2), 'Expected to contain: ' + expectedErrorRow2);
            System.assertEquals(
                true,
                result.toString().contains(Label.CCH_DUPLICATED_CRITERIA),
                'Expected to contain: ' + Label.CCH_DUPLICATED_CRITERIA
            );
        }
    }

    private static void setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    private static User getTestUser() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        return testUser;
    }

    private static final String TEST_NODE = 'testNode';
    private static final String TEST_FIELD = 'testField';
    private static final String TEST_EMPTY_FIELD = '';
    private static final String TEST_OPERATOR = 'equals';
    private static final String TEST_VALUE = 'testValue';
    private static final String TEST_EMPTY_VALUE = '';
}