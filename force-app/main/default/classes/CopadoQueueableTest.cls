@IsTest
public with sharing class CopadoQueueableTest implements CopadoQueueable {
    @TestVisible private static Boolean throwExceptionOnExecute = false;
    @TestVisible private static Boolean throwExceptionOnCancel = false;

    public void execute(String payload) {
        if(throwExceptionOnExecute) {
            throw new ApplicationException('Callback Execution Failed');
        }
    }
    public void cancel(String payload) {
        if(throwExceptionOnCancel) {
            throw new ApplicationException('Callback Cancelation Failed');
        }
    }
}