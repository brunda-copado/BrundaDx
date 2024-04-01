@isTest
private with sharing class GenerateScaRulesetActionTest {
    
    @TestSetup
    private static void makeData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            Static_Code_Analysis_Settings__c scas = TestMethodUtilities.createScaSetting('Test PMD');
            insert scas;
        }
    }
    @isTest
    private static void validateExecute() {
        System.runAs(getStandardUser()) {
		Static_Code_Analysis_Settings__c scas = [SELECT ID FROM Static_Code_Analysis_Settings__c LIMIT 1 ];
        List<GenerateScaRulesetAction.Request> requests = new List<GenerateScaRulesetAction.Request>();
        GenerateScaRulesetAction.Request request = new GenerateScaRulesetAction.Request(scas.Id);
        requests.add(request);
		Test.startTest();
        String res = '[{ "name": "ExcessiveClassLength", "ref": "category/apex/design.xml/ExcessiveClassLength", "priority": "2", "message": "Avoid really long classes (lines of code)" }, { "name": "ExcessiveParameterList", "ref": "category/apex/design.xml/ExcessiveParameterList", "priority": "3", "message": "Avoid long parameter lists" }, { "name": "ExcessivePublicCount", "ref": "category/apex/design.xml/ExcessivePublicCount", "priority": "4", "message": "This class has too many public methods and attributes" }]';
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		List<GenerateScaRulesetAction.Result> results = GenerateScaRulesetAction.execute(requests);
		List<Static_Code_Analysis_Rule__c> rules = [SELECT Priority__c FROM Static_Code_Analysis_Rule__c WHERE Static_Code_Analysis_Settings__c = :scas.Id ORDER BY Priority__c];
		Test.stopTest();
        System.assertEquals(3, rules.size(),'expected 3 but found '+rules.size());
        }
	}
    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        setOrgTimeZone(standardUser);
        return standardUser;
    }

    private static void setOrgTimeZone(User user) {
        List<Organization> organizations = [SELECT TimeZoneSidKey FROM Organization LIMIT 1];
        if(!organizations.isEmpty()){
            user.TimeZoneSidKey = organizations.get(0).TimeZoneSidKey;
            update user;
        }
    }
    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }
}