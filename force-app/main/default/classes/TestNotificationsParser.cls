@IsTest
private class TestNotificationsParser {
    @IsTest
    private static void initializeOnInsert(){
        // Setup
        Copado_Notification__c n = new Copado_Notification__c(
            Message__c = '{"isFinished": true, "isSuccess": false, "matchingKeysString": "GitCommit"}'
        );
        
        //Exercise
        insert n;
        
        // Verify
        n = [SELECT isFinished__c, Matching_Key__c FROM Copado_Notification__c LIMIT 1];
        System.assertEquals(true, n.isFinished__c);
        System.assertEquals('GitCommit', n.Matching_Key__c);
    }
    
    @IsTest
    private static void initializeOnUpdate(){
        // Setup
        Copado_Notification__c n = new Copado_Notification__c(
            Message__c = '{"status": "terminated", "isSuccess": true}'
        );
        insert n;
        
        // Excercise
        update n;
        
        // Verify
        n = [SELECT isSuccess__c, Status__c FROM Copado_Notification__c LIMIT 1];
        System.assertEquals('terminated', n.status__c);
        System.assertEquals(true, n.isSuccess__c);
    }
}