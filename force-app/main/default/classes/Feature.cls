@SuppressWarnings('PMD.PropertyNamingConventions, PMD.AvoidGlobalModifier')
// PropertyNamingConventions: Needed for Skeleton Attributes, as we are using a name starting by uppercase
// AvoidGlobalModifier: As we want to expose the services as global, thus the modifier

global inherited sharing class Feature implements CopadoDomain {
    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Feature Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static Boolean isCCHEnabled() {
        // Note: not setting savepoint as this service is not writing to database

        try {
            return CheckCCHEnabled.execute();
        } catch (Exception e) {
            throw new ApplicationException(e.getMessage());
        }
    }

    global static Boolean isCCMEnabled() {
        // Note: not setting savepoint as this service is not writing to database

        try {
            return CheckCCMEnabled.execute();
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }
}