@isTest
private with sharing class RetrieveOrgTestClassesTest {
    
    @isTest
    private static void execute() {
        System.runAs(getTestUser()) {
            // Setup
            Org__c testOrg = getCredential();
            String fixedResponse = fixedResponse();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete',fixedResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            
            //Exercise
            Test.startTest();
            String result = RetrieveOrgTestClasses.execute(testOrg.id);
            Test.stopTest();
            
            // Verify
            String content = (String) ((Map<String, Object>) JSON.deserializeUntyped(fixedResponse)).get('content');
            System.assertEquals(content, result, 'Content of response is not correct.');
        }
    }
    
    @isTest
    private static void isToggleOff() {
        System.runAs(getTestUser()) {
            // Setup
            UniversalFeatureToggle.mockValue = 0;
            
            //Exercise
            Boolean toggle = RetrieveOrgTestClasses.isApexTestsV2ToggleOff();
            
            //Verify
            System.assertEquals(True,toggle);
        }
    }
    
    @isTest
    private static void isToggleOn() {
        System.runAs(getTestUser()) {
            // Setup
            UniversalFeatureToggle.mockValue = 1;
            
            //Exercise
            Boolean toggle = RetrieveOrgTestClasses.isApexTestsV2ToggleOff();
            
            //Verify
            System.assertEquals(False,toggle);
        }
    }
    
    @TestSetup
    private static void setupUser() {
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        System.runAs(getTestUser()) {
            createMockData();
        }
    }
    
    private static User getTestUser() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
        return testUser;
    }
    
    private static void createMockData() {
        Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
        insert credential;
    }
    
    private static String fixedResponse() {
        return '{' +
            '"content" : "{' +
            '\\"searchRecords\\":[{\\"attributes\\":{\\"type\\":\\"ApexClass\\",\\"url\\":\\"se\\"},\\"Name\\":\\"MockResponseTest\\",\\"NamespacePrefix\\":null}]'+
            '}"' +
            '}';
    }
    
    private static Org__c getCredential() {
        return [SELECT name FROM Org__c LIMIT 1];
    } 
}