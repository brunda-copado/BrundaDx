@IsTest
private class ApexClassAccountTest {

    @isTest static void testDefaultDescription(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = ApexClassAccount.setDefaultDescription(acc);
        System.assertEquals('Default description', acc.Description, 'When description is null, it is updated to Default description');
    }

    @isTest static void testDefaultPhone(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = ApexClassAccount.setDefaultPhone(acc);
        System.assertEquals('9879879877', acc.Phone, 'Default phone number is 9879879877');
    }

    @isTest static void testDefaultURLnew(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = ApexClassAccount.setDefaultURL(acc);
        System.assertEquals('www.copado.com', acc.Website, 'Default website is www.copado.com');

    }

}