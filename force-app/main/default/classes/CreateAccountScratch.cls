public with sharing class CreateAccountScratch {
    public CreateAccountScratch() {
            System.debug('hellow wordl');
            Account newAccount=new Account();
            newAccount.Name='from scratch';
            insert newAccount;
    }
}