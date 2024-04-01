@isTest
private with sharing class CustomHighlightPanelCtrlTest {
    @testSetup private static void testSetup()
    {
        Id recordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByName().get('User Story').getRecordTypeId();
        User_Story__c userStory = new User_Story__c(User_Story_Title__c='Ctrl', RecordTypeId = recordTypeId );
        insert userStory;
    }

    @isTest private static void getFieldListandRecordTypeTest(){
        
        //Setup
        User_Story__c userStory = [SELECT Id FROM User_Story__C WHERE User_Story_Title__c='Ctrl'];   
        String namespace = Settings.ns;
        
        //Exercise
        Test.startTest();
        List<customHighlightPanelController.FieldDefinition> fieldDefinition = CustomHighlightPanelController.getFieldList(userStory.Id, namespace+'Commit_Page');
        Test.stopTest();
        
        // Verify 
        System.assert(fieldDefinition.size()>0);

    }

    @isTest private static void getObjectNameTest(){
        //Setup
        User_Story__c userStory = [SELECT Id FROM User_Story__C WHERE User_Story_Title__c='Ctrl'];  
        
        //Exercise
        Test.startTest();
        String objectName = CustomHighlightPanelController.getObjectPluralName(userStory.Id);
        Test.stopTest();

        // Verify 
        System.assertEquals(objectName, 'User Stories');
    }

    @isTest private static void getRecordTypeNameTest(){
        //Setup
        User_Story__c userStory = [SELECT Id FROM User_Story__C WHERE User_Story_Title__c='Ctrl'];  
        
        //Exercise
        Test.startTest();
        String recordName = CustomHighlightPanelController.getRecordTypeName(userStory.Id);
        Test.stopTest();

        // Verify 
        System.assert(String.isNotBlank(recordName));
    }
}