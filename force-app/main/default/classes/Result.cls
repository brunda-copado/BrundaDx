@IsTest
public class Result extends DomainBuilder {
    public Result() {
        super(Result__c.sObjectType);

        jobType('mockJob');
        status('Completed');
    }

    public Result jobType(String value) {
        return (Result) set(Result__c.Job_Type__c, value);
    }

    public Result status(String value) {
        return (Result) set(Result__c.Status__c, value);
    }

    public Result errMsg(String value) {
        return (Result) set(Result__c.Error_Message__c, value);
    }

    public Result progress(String value) {
        return (Result) set(Result__c.Progress_Status__c, value);
    }

    public Result resultData(String value) {
        return (Result) set(Result__c.Result_Data__c, value);
    }

    public Result step(Id value) {
        return (Result) set(Result__c.JobStep__c, value);
    }

    public Result test(Id value) {
        return (Result) set(Result__c.Test__c, value);
    }

    public Result function(Id value) {
        return (Result) set(Result__c.Function__c, value);
    }

    public Result startTime(Datetime value) {
        return (Result) set(Result__c.Start_Time__c, value);
    }

    public Result functionWorkerSize(String value) {
        return (Result) set(Result__c.Function_Worker_Size__c, value);
    }

    public Result timeout(Decimal value) {
        return (Result) set(Result__c.Timeout__c, value);
    }
}