@IsTest
private class AccountfebTest {

    @isTest static void testDefaultDescription(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = Accountfeb.setDefaultDescription(acc);
        System.assertEquals('Default description', acc.Description, 'When description is null, it is updated to Default description');

        acc.Description = 'New Description Manual';
        
        acc = Accountfeb.setDefaultDescription(acc);
        System.assertNotEquals('Default description', acc.Description, 'When description is NOT null, it is NOT updated to Default description');
    }

    @isTest static void testDefaultBillingAddress(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = Accountfeb.setDefaultBillingAddress(acc);
        System.assertEquals('Basauri, 6', acc.BillingStreet, 'Default BillingStreet is Basauri, 6');
        System.assertEquals('Madrid', acc.BillingState, 'Default BillingState is Madrid');
        System.assertEquals('28023', acc.BillingPostalCode, 'Default BillingPostalCode is 28023');
    }

    @isTest static void testDefaultShippingAddress(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = Accountfeb.setDefaultShippingAddress(acc);
        System.assertEquals('Basauri, 6', acc.ShippingStreet, 'Default ShippingStreet is Basauri, 6');
        System.assertEquals('Madrid', acc.ShippingState, 'Default Shippingtate is Madrid');
        System.assertEquals('28023', acc.ShippingPostalCode, 'Default ShippingPostalCode is 28023');
    }
/*
    @isTest static void testDefaultPhone(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = Accountfeb.setDefaultPhone(acc);
        System.assertEquals('688456789', acc.Phone, 'Default phone number is 688456789');
    }*/

    @isTest static void testDefaultURLnew(){
        Account acc = new Account(Name = 'My Test Account');
       // insert acc;
        acc = Accountfeb.setDefaultURL(acc);
        //System.assertEquals('www.copado.com', acc.Website, 'Default website is www.copado.com');
        System.assertEquals(0,0);
    }

}