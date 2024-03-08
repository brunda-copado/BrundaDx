@isTest
public class kompalAcc2Test {
@isTest static void testaccountLogicMethodOne(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = KompalAcc2.accountLogicMethodOne(acc);
        System.assertEquals('Default description', acc.Description, 'When description is null, it is updated to Default description');

        acc.Description = 'New Description Manual';
        
        acc = KompalAcc2.accountLogicMethodOne(acc);
        System.assertNotEquals('Default description', acc.Description, 'When description is NOT null, it is NOT updated to Default description');
    }

    @isTest static void testaccountLogicMethodTwo(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = KompalAcc2.accountLogicMethodTwo(acc);
        System.assertEquals('Basauri, 6', acc.BillingStreet, 'Default BillingStreet is Basauri, 6');
        System.assertEquals('Madrid', acc.BillingState, 'Default BillingState is Madrid');
        System.assertEquals('28023', acc.BillingPostalCode, 'Default BillingPostalCode is 28023');
    }

    @isTest static void testaccountLogicMethodThree(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = KompalAcc2.accountLogicMethodThree(acc);
        System.assertEquals('Basauri, 6', acc.ShippingStreet, 'Default ShippingStreet is Basauri, 6');
        System.assertEquals('Madrid', acc.ShippingState, 'Default Shippingtate is Madrid');
        System.assertEquals('28023', acc.ShippingPostalCode, 'Default ShippingPostalCode is 28023');
    }

    @isTest static void testaccountLogicMethodFour(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = KompalAcc2.accountLogicMethodFour(acc);
        System.assertEquals('688456789', acc.Phone, 'Default phone number is 688456789');
    }

    @isTest static void testaccountLogicMethodFive(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = KompalAcc2.accountLogicMethodFive(acc);
        System.assertEquals('www.copado.com', acc.Website, 'Default website is www.copado.com');
    }
}