trigger AccontOperationTrigger on Account (before insert) {
for(Account a : Trigger.New) {
        a = AccountOperations.setDefaultDescription(a);
    } 
}