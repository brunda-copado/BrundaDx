public with sharing class ctx_runAccountLogic {
    public ctx_runAccountLogic() {
        System.debug('I am constructed!');
    }

    Public static Account accountLogicMethodOne(Account a){
        If (a.Description != null) return a;
        Else {
            a.Description = 'Default description';
            return a;
        }
    }
    public static Account accountLogicMethodTwo(Account a){
        a.billingstreet = 'Basauri, 6'; 
        a.billingstate = 'Madrid'; 
        a.billingpostalcode ='28023'; 
        return a;
    }
    public static Account accountLogicMethodThree(Account a){
        a.shippingstreet = 'Basauri, 6'; 
        a.shippingstate = 'Madrid';
        a.shippingpostalcode ='28023';
        return a;
    }
    public static Account accountLogicMethodFour(Account a) {
        a.Phone='688456789';
        return a;
    }
}