@isTest
public class KompalAcc3Test {
  @isTest static void testcaseLogicMethodOne(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = kompalAcc3.caseLogicMethodOne(acc);
        System.assertEquals('Default description', acc.Description, 'When description is null, it is updated to Default description');

        acc.Description = 'New Description Manual';
        
        acc = kompalAcc3.caseLogicMethodOne(acc);
        System.assertNotEquals('Default description', acc.Description, 'When description is NOT null, it is NOT updated to Default description');
    }

    @isTest static void testcaseLogicMethodTwo(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = kompalAcc3.caseLogicMethodTwo(acc);
        System.assertEquals('Basauri, 6', acc.BillingStreet, 'Default BillingStreet is Basauri, 6');
        System.assertEquals('Madrid', acc.BillingState, 'Default BillingState is Madrid');
        System.assertEquals('28023', acc.BillingPostalCode, 'Default BillingPostalCode is 28023');
    }

    @isTest static void testcaseLogicMethodThree(){
        Account acc = new Account(Name = 'My Test Account');
        insert acc;
        acc = kompalAcc3.caseLogicMethodThree(acc);
        System.assertEquals('Basauri, 6', acc.ShippingStreet, 'Default ShippingStreet is Basauri, 6');
        System.assertEquals('Madrid', acc.ShippingState, 'Default Shippingtate is Madrid');
        System.assertEquals('28023', acc.ShippingPostalCode, 'Default ShippingPostalCode is 28023');
    }
}