@IsTest
private class VerifyThatFunctionsTest {
	
    @IsTest
    private static void insertStandardFunction() {
        
        // Setup
        Exception expectedException = null;
        
        Settings__c setting = new Settings__c(); 
        setting.Enable_Standard_Function_Edit__c = false;
        setting.SetupOwnerId = UserInfo.getOrganizationId();
        insert setting;
        
        // Exercise
        try {
            insert new Function__c(API_Name__c = 'TestStandard', Type__c = 'Standard', Script__c = 'echo');
        }
        catch(Exception ex) {
            expectedException = ex;
        }
        
        // Verify
        System.assertNotEquals(null, expectedException);
    }
    
    @IsTest
    private static void insertStandardFunctionWithSettingEnabled() {
        
        // Setup
        Exception expectedException = null;
        
        Settings__c setting = new Settings__c(); 
        setting.Enable_Standard_Function_Edit__c = true;
        setting.SetupOwnerId = UserInfo.getOrganizationId();
        insert setting;
        
        // Exercise
        try {
            insert new Function__c(API_Name__c = 'TestStandard', Type__c = 'Standard', Script__c = 'echo');
        }
        catch(Exception ex) {
            expectedException = ex;
        }
        
        // Verify
        System.assertEquals(null, expectedException);
    }
    
    @IsTest
    private static void updateStandardFunctionWithSettingEnabled() {
        
        // Setup
        Exception expectedException = null;
        
        Settings__c setting = new Settings__c(); 
        setting.Enable_Standard_Function_Edit__c = true;
        setting.SetupOwnerId = UserInfo.getOrganizationId();
        insert setting;
        
        Function__c function = new Function__c();
        function.API_Name__c = 'TestStandard';
        function.Type__c = 'Standard';
        function.Script__c = 'echo';
        insert function;
        
        setting.Enable_Standard_Function_Edit__c = false;
        update setting;
        
        // Exercise
        try {
            function.Script__c = 'echo2';
            update function;
        }
        catch(Exception ex) {
            expectedException = ex;
        }
        
        // Verify
        System.assertNotEquals(null, expectedException);
    }
}