@IsTest
public class WebhookSetting extends DomainBuilder {
    
    public WebhookSetting() {
        super(Webhook_Settings__c.sObjectType);
        name(new Random().string(10));
        action('TestClassAction');
        user(UserInfo.getUserId());
        key(new Random().string(10));
        startDate(DateTime.now().addDays(-1));
        endDate(DateTime.now().addDays(1));
    }
    public WebhookSetting name(String value) {
        return (WebhookSetting) set(Webhook_Settings__c.Name, value);
    }
    public WebhookSetting action(String value) {
        return (WebhookSetting) set(Webhook_Settings__c.Action__c, value);
    }
    public WebhookSetting user(String value) {
        return (WebhookSetting) set(Webhook_Settings__c.UserId__c, value);
    }
    public WebhookSetting key(String value) {
        return (WebhookSetting) set(Webhook_Settings__c.Key__c, value);
    }
    public WebhookSetting startDate(DateTime value) {
        return (WebhookSetting) set(Webhook_Settings__c.Start_Date__c, value);
    }
    public WebhookSetting endDate(DateTime value) {
        return (WebhookSetting) set(Webhook_Settings__c.End_Date__c, value);
    }
}