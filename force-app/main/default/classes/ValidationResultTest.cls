@isTest
private with sharing class ValidationResultTest {
    @isTest
    private static void successValidationResult() {
        // Exercise
        ValidationResult result = new ValidationResult();

        // Verify
        System.assertEquals(false, result.isError());
        System.assertEquals(true, String.isBlank(result.toString()));
    }

    @isTest
    private static void errorValidationResult() {
        // Setup
        String testError1 = 'error 1';
        String testError2 = 'error 2';

        // Exercise
        ValidationResult result = new ValidationResult();
        result.addError(testError1);
        result.addError(testError2);

        // Verify
        String expectedAsString = testError1 + '\n' + testError2;

        System.assertEquals(true, result.isError());
        System.assertEquals(expectedAsString, result.toString());
    }
}