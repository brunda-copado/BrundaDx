@IsTest
private with sharing class EnvironmentalVariableTriggerTest {
    @IsTest
    private static void checkDuplicates() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        
        Test.startTest();
        Environmental_Variable__c ev1 = new Environmental_Variable__c(
            Name = 'A',
            Value__c = 'A',
            Environment__c = environments[0].Id
        );
        insert ev1;
        
        Environmental_Variable__c ev2 = new Environmental_Variable__c(
            Name = 'A',
            Value__c = 'B',
            Environment__c = environments[0].Id
        );
        try {
            insert ev2;
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(Label.DUPLICATE_EV_NAME_AND_ENV),
                e.getMessage()
            );
        }
        
        Environmental_Variable__c ev3 = new Environmental_Variable__c(
            Name = 'B',
            Value__c = 'A',
            Environment__c = environments[0].Id
        );
        
        try {
            insert ev3;
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(Label.DUPLICATE_EV_VAL_AND_ENV),
                e.getMessage()
            );
        }
        
        Environmental_Variable__c ev4 = new Environmental_Variable__c(
            Name = 'C',
            Value__c = 'D',
            Environment__c = environments[0].Id
        );
        insert ev4;
        
        System.assertNotEquals(
            ev4.Id,
            null,
            'Error in inserting environmental variable'
        );
        
        Environmental_Variable__c ev5 = new Environmental_Variable__c(
            Name = 'var1',
            Value__c = 'true',
            Scope__c = 'classes/AccountWrapper.cls;classes/OppWrapper.cls;CustomSettingValues/SAP_URL__c.object',
            Environment__c = environments[0].Id
        );
        insert ev5;
        
        Environmental_Variable__c ev6 = new Environmental_Variable__c(
            Name = 'var2',
            Value__c = 'true',
            Scope__c = 'classes/AccountWrapper.cls;classes/OppWrapper.cls;CustomSettingValues/SAP_URL__c.object',
            Environment__c = environments[0].Id
        );
        try {
            insert ev6;
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(Label.DUPLICATE_EV_VAL_ENV_AND_SCOPE),
                e.getMessage()
            );
        }
        
        Environmental_Variable__c ev7 = new Environmental_Variable__c(
            Name = 'var10',
            Value__c = 'false',
            Scope__c = 'classes/AccountWrapper.cls;classes/OppWrapper.cls;CustomSettingValues/SAP_URL__c.object',
            Environment__c = environments[0].Id
        );
        
        try {
            insert ev7;
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(Label.DUPLICATE_EV_NAME_ENV_AND_SCOPE),
                e.getMessage()
            );
        }
        
        Environmental_Variable__c ev8 = new Environmental_Variable__c(
            Name = 'var1',
            Value__c = 'false',
            Scope__c = 'classes/AccountWrapper.cls;CustomSettingValues/SAP_URL__c.object;classes/OppWrapper.cls',
            Environment__c = environments[0].Id
        );
        
        try {
            insert ev8;
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(Label.DUPLICATE_EV_VAL_ENV_AND_SCOPE),
                e.getMessage()
            );
        }
        
        Environmental_Variable__c ev9 = new Environmental_Variable__c(
            Name = 'var1',
            Value__c = 'false',
            Scope__c = 'CustomSettingValues/SAP_URL__c.object',
            Environment__c = environments[0].Id
        );
        try{
            insert ev9;
        }catch(Exception e){
            System.assertEquals(
            ev9.Id,
            null,
            'Error in inserting environmental variable'
        	);
        }       
                
        Test.stopTest();
    }
    
    @IsTest
    private static void checkForScopeChange() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        
        Test.startTest();
        Environmental_Variable__c ev1 = new Environmental_Variable__c(
            Name = 'A',
            Value__c = 'A',
            Scope__c = 'object/*;',
            Environment__c = environments[0].Id
        );
        insert ev1;
        
        try {
            ev1.Scope__c = 'Classes/accountWrapper.cls;';
            update ev1;
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(Label.SCOPE_CHANGE_ERROR),
                e.getMessage()
            );
        }
        
        Test.stopTest();
        
    }
}