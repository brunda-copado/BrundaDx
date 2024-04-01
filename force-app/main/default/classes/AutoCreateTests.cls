public with sharing class AutoCreateTests {
    private Id parentId;
    private String sObjectName;

    //CTOR

    public AutoCreateTests(Id parentId, String sObjectName) {
        this.parentId = parentId;
        this.sObjectName = sObjectName;
    }

    //PUBLIC

    public Test__c execute(Id extensionConfigurationId, TestTool__mdt testTool) {
        try {
            return initTestFor(extensionConfigurationId, testTool);
        } catch (Exception ex) {
            throw new ApplicationException(
                Label.Auto_Creation_of_Test_Exception +
                ' ' +
                ex.getTypeName() +
                ': ' +
                ex.getMessage().replaceAll('\'', '')
            );
        }
    }

    //PRIVATE

    private Test__c initTestFor(Id extensionConfigurationId, TestTool__mdt testTool) {
        Test__c test = new Test__c();
        test.ExtensionConfiguration__c = extensionConfigurationId;

        switch on sObjectName {
            when 'Promotion__c' {
                test.Promotion__c = parentId;
                test.Name = testTool.MasterLabel + ' - ' + new PromotionsSelector().byIds(new Set<Id>{ parentId })[0].Name;
            }
            when 'Application__c' {
                test.Application__c = parentId;
                test.Name = testTool.MasterLabel + ' - ' + [SELECT Id, Name FROM Application__c WHERE Id = :parentId WITH SECURITY_ENFORCED].Name;
            }
            when 'Application_Feature__c' {
                test.Feature__c = parentId;
                test.Name = testTool.MasterLabel + ' - ' + new FeaturesSelector().byIds(new Set<Id>{ parentId })[0].Name;
            }
            when 'User_Story_Commit__c' {
                User_Story_Commit__c userStoryCommit = new UserStoryCommitsSelector().byIds(new Set<Id>{ parentId })[0];
                test.User_Story__c = userStoryCommit.User_Story__c;
                test.Name = testTool.MasterLabel + ' - ' + userStoryCommit.User_Story__r.Name;
            }
            when else {
                test.Parent_Id__c = parentId;
                test.Name = testTool.MasterLabel + ' - ' + parentId;
            }
        }

        if (testTool.Automate_Test_Readiness__c && String.isNotBlank(testTool.Test_Readiness_Logic__c)) {
            runToolAction(testTool.Test_Readiness_Logic__c, new List<Test__c>{ test });
        } else if (testTool.Automate_Test_Readiness__c && String.isBlank(testTool.Test_Readiness_Logic__c)) {
            test.ReadyToRun__c = true;
        } else {
            test.ReadyToRun__c = false;
        }

        Utilities.Secure_DML(test, Utilities.DML_Action.UPS, Schema.SObjectType.Test__c);
        return test;
    }

    private void runToolAction(String toolAction, List<Test__c> tests) {
        if (String.isNotBlank(toolAction)) {
            Type callbackClass = typeByName(toolAction);
            ((TestReadinessInterface) callbackClass.newInstance()).execute(tests);
        }
    }

    private Type typeByName(String toolAction) {
        String namespace = toolAction.contains('.') ? toolAction.substringBefore('.') : '';
        String className = toolAction.contains('.') ? toolAction.substringAfter('.') : toolAction;

        Type result = Type.forName(namespace, className);
        if (result == null) {
            throw new ApplicationException(Label.InvalidCallback + ' ' + toolAction);
        }

        return result;
    }
}