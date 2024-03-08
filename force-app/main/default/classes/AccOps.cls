public class AccOps {
    public static Account setDefaultDescription(Account a) {
        a.Description = 'Default description';
        return a;
    }
        public static Account setDefaultPhone(Account a) {//Dev01
        a.Phone = '9879879877';
          return a;
}
   public static Account setDefaultURL(Account a) {//DEV2
        a.Website = 'www.copado.com';//DEV
          return a;
}
}