public with sharing class ManualTestsScriptSelectorCtrl {
    @testVisible
    private static List<Test_Script__c> mockTestScripts;

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> getRecentlyViewedTestScripts() {
        List<sObject> recentlyViewed;

        if (!Test.isRunningTest()) {
            recentlyViewed = [SELECT Name, Test_Title__c FROM Test_Script__c WITH SECURITY_ENFORCED ORDER BY LastViewedDate DESC NULLS LAST LIMIT 5];
        } else {
            recentlyViewed = mockTestScripts;
        }

        List<LookupSearchResult> result = new List<LookupSearchResult>();

        for (SObject obj : recentlyViewed) {
            String name = String.valueOf(obj.get('Name'));
            String subtitle = String.valueOf(obj.get('Test_Title__c'));
            result.add(new LookupSearchResult(obj.Id, 'Test Script', 'standard:article', name, subtitle));
        }

        return result;
    }

    @AuraEnabled
    public static void saveTestScriptSuitesFor(Id testId, String body) {
        try {
            if (String.isNotBlank(body)) {
                List<TestSuiteScriptWrapper> scriptsWrapper = parseJson(body);

                deleteTestSuiteScriptsFor(testId, scriptsWrapper);
                upsertTestSuiteScriptsFor(testId, scriptsWrapper);
            } else {
                new ApplicationException(Label.NODATATODISPLAY).throwAuraHandled();
            }
        } catch (Exception e) {
            throw new ApplicationException(Label.NODATATODISPLAY).auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Test_Script__c> getSavedTestScriptsFor(Id recordId) {
        try {
            List<Test_Script__c> result = new List<Test_Script__c>();
            if (recordId != null) {
                result = getSavedScriptsInfoFor(recordId);
            } else {
                new ApplicationException(Label.NODATATODISPLAY).throwAuraHandled();
            }

            return result;
        } catch (Exception e) {
            throw new ApplicationException(Label.NODATATODISPLAY).auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Test_Script__c> getSelectedScriptDetailsFor(Id scriptId, Id testId) {
        List<Test_Script__c> result = new List<Test_Script__c>();
        if (scriptId != null) {
            result = getTestScript(scriptId, testId);

            if (result[0].Script_Steps__r.isEmpty()) {
                new ApplicationException(Label.SuiteMustContainSteps).throwAuraHandled();
            }
        } else {
            new ApplicationException(Label.NODATATODISPLAY).throwAuraHandled();
        }

        return result;
    }

    //PRIVATE

    private static List<Test_Script__c> getSavedScriptsInfoFor(Id testId) {
        List<Test_Script__c> result = new List<Test_Script__c>();

        String whereClause = 'IN (SELECT Test_Script__c FROM Test_Suite_Script__c WHERE Test__c = :testId)';
        result = Database.query(getQuery(whereClause));

        return result;
    }

    private static List<Test_Script__c> getTestScript(Id testScriptId, Id testId) {
        List<Test_Script__c> result = new List<Test_Script__c>();

        String whereClause = '= :testScriptId';
        result = Database.query(getQuery(whereClause));

        return result;
    }

    private static String getQuery(String whereClause) {
        String result =
            'SELECT Id, Name, Test_Title__c, Prerequisites__c, Expected_Result__c, Project__c, Risk__c,' +
            ' (SELECT Id, Order__c, Test_Script__c FROM Test_Suite_Scripts__r WHERE Test__c = :testId LIMIT 1),' +
            ' (SELECT Id, Test_Script__c, Name, Action_Description__c, Expected_Result__c, Guidance_notes__c, Order__c FROM Script_Steps__r)' +
            ' FROM Test_Script__c WHERE ID ' +
            whereClause +
            ' WITH SECURITY_ENFORCED';

        return result;
    }

    private static List<TestSuiteScriptWrapper> parseJson(String body) {
        return (List<TestSuiteScriptWrapper>) System.JSON.deserialize(body, List<TestSuiteScriptWrapper>.class);
    }

    private static void upsertTestSuiteScriptsFor(Id testId, List<TestSuiteScriptWrapper> scriptsWrapper) {
        List<Test_Suite_Script__c> scriptsToUpsert = new List<Test_Suite_Script__c>();

        for (TestSuiteScriptWrapper suiteScript : scriptsWrapper) {
            scriptsToUpsert.add(prepareUpsertTestSuiteScript(testId, suiteScript));
        }

        if (
            !scriptsToUpsert.isEmpty() &&
            Schema.sObjectType.Test_Suite_Script__c.isCreateable() &&
            Schema.sObjectType.Test_Suite_Script__c.isUpdateable()
        ) {
            upsert scriptsToUpsert;
        }
    }

    private static Test_Suite_Script__c prepareUpsertTestSuiteScript(Id testId, TestSuiteScriptWrapper suiteScript) {
        return new Test_Suite_Script__c(
            Id = suiteScript.suiteScriptId,
            Test__c = testId,
            Test_Script__c = suiteScript.testScriptId,
            Order__c = suiteScript.order
        );
    }

    private static void deleteTestSuiteScriptsFor(Id testId, List<TestSuiteScriptWrapper> scriptsWrapper) {
        List<Test_Suite_Script__c> deleteTestSuiteScripts = new List<Test_Suite_Script__c>();

        List<Test_Suite_Script__c> existingTestSuiteScripts = getExistingTestSuiteScripts(testId);

        Set<Id> newScriptIds = getScriptIds(scriptsWrapper);

        if (!existingTestSuiteScripts.isEmpty() && !newScriptIds.isEmpty()) {
            for (Test_Suite_Script__c suiteScript : existingTestSuiteScripts) {
                if (!newScriptIds.contains(suiteScript.Id)) {
                    deleteTestSuiteScripts.add(suiteScript);
                }
            }

            if (!deleteTestSuiteScripts.isEmpty() && Schema.sObjectType.Test_Suite_Script__c.isDeletable()) {
                delete deleteTestSuiteScripts;
            }
        }
    }

    private static List<Test_Suite_Script__c> getExistingTestSuiteScripts(Id testId) {
        return [SELECT Id FROM Test_Suite_Script__c WHERE Test__c = :testId];
    }

    private static Set<Id> getScriptIds(List<TestSuiteScriptWrapper> scriptsWrapper) {
        Set<Id> result = new Set<Id>();

        for (TestSuiteScriptWrapper suiteScriptWrap : scriptsWrapper) {
            result.add(suiteScriptWrap.suiteScriptId);
        }

        return result;
    }

    //INNER
    private class TestSuiteScriptWrapper {
        private Id testScriptId;
        private Id suiteScriptId;
        private Integer order;
    }
}