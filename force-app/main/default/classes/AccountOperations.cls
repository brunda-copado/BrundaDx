public class AccountOperations {
    public static Account setDefaultDescription(Account a) {
        a.Description = 'Test'; // testing 21.3
        return a; // Reg 21.3
    }
}