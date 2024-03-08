public with sharing class ctx_runCaseLogic {
    public ctx_runCaseLogic() {
        System.debug('I am constructed!');
    }
    // conflict in source org dev1
    Public static Account caseLogicMethodOne(Account a){
        If (a.Description != null) return a;
        Else {
            a.Description = 'Default description';
            return a;
        }
    }
    public static Account caseLogicMethodTwo(Account a){
        a.billingstreet = 'Basauri, 6'; 
        a.billingstate = 'Madrid'; 
        a.billingpostalcode ='28023'; 
        return a;
    }
    public static Account caseLogicMethodThree(Account a){
        a.shippingstreet = 'Basauri, 6'; 
        a.shippingstate = 'Madrid';
        a.shippingpostalcode ='28023';
        return a;
    }
    public static Account caseLogicMethodFour(Account a) {
        a.Phone='688456789';
        return a;
    }
    public static Account caseLogicMethodFive(Account a) {
        a.website = 'www.copado.com'; 
        return a;
    }
}