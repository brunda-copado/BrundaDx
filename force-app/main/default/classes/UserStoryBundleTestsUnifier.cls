@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing virtual class UserStoryBundleTestsUnifier {
    // GLOBAL

    /*
     * Use this method to unify and consolidate all the tests records for the given Test Tool under a single test record (or multiple if needed).
     * Do not insert the new records, just return them and we will insert in bulk with the rest of the tests.
     */
    global virtual List<Test__c> unifyTests(List<Test__c> testToUnify) {
        return new List<Test__c>();
    }

    /* Use this method to perform additional logic on unified tests (like reading attachments, merge files, etc.).
     * You can insert new records in this method, just take into account best practices for Salesforce, as this will be executed per each Test Tool you have configured.
     */
    global virtual void additionalLogicAfterUnify(List<Test__c> unifiedTests) {
        return;
    }
}