@IsTest
private class PublishNotificationsEventTest {
    @IsTest
    private static void eventPublishedForTypeGit() {
        // Setup
        Copado_Notification__c n = new Copado_Notification__c(
            Message__c = '{"status": "terminated","isFinished":true,"isSuccess":false}',
            Type__c = 'GitCommit'
        );
        insert n;
        
        // Exercise
        List<Database.SaveResult> result = new PublishNotificationsEvent(new List<Copado_Notification__c>{ n }).execute();
        
        // Verify
        System.assert(result.get(0).isSuccess());
    }
    
    @IsTest
    private static void noEventPublishedForOtherOperation() {
        // Setup
        Copado_Notification__c n = new Copado_Notification__c(
            Message__c = '{"status": "terminated","isFinished":true,"isSuccess":false}',
            Type__c = 'Promotion'
        );
        insert n;
        
        // Exercise
        List<Database.SaveResult> result = new PublishNotificationsEvent(new List<Copado_Notification__c>{ n }).execute();
        
        // Verify
        System.assert(result.isEmpty());
    }
}