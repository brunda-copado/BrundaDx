@RestResource(urlMapping='/FunctionWebEvent/*')
global with sharing class FunctionWebEvent {
    public static Boolean updateCredits = true;

    @HttpPost
    @SuppressWarnings('PMD.VariableNamingConventions, PMD.FormalParameterNamingConventions, PMD.ExcessiveParameterList, PMD.AvoidDeeplyNestedIfStmts')
    global static void doPost(String result_id, String status, String error_message, String result_data, Boolean is_finished, Boolean is_success) {
        Logger.trace(result_id, 'FunctionWebEvent.doPost', 'Result Data: ' + result_data + 'Error Message: ' + error_message, null);

        MC_Result__e event = new MC_Result__e(
            ResultId__c = result_id,
            Progress_Status__c = status,
            Error_Message__c = error_message,
            Result_Data__c = result_data,
            IsFinished__c = is_finished,
            IsSuccess__c = is_success
        );

        List<Result__c> results = new ResultsSelector().inProgressByIds(new Set<Id>{ event.ResultId__c });

        if (!results.isEmpty()) {
            Result__c result = updatedResult(results[0], event);
            DML.safeUpdate(result, 'Could not update a Result object on a Function Web Event ( FunctionWebEvent.doPost class )');

            CallbackHelper.executeCallback(result);
        }
    }

    // PRIVATE

    private static Result__c updatedResult(Result__c record, MC_Result__e event) {
        Result__c result = clone(record);

        Integer usedMinutes = FunctionCreditHelper.usedMinutes(record.Start_Time__c);

        result.Custom_Function_Used_Minutes__c = usedMinutes;
        result.Custom_Function_Used_Credits__c = FunctionCreditHelper.usedCredits(usedMinutes, record.Function_Worker_Size__c);

        if (event.IsFinished__c == true) {
            result.End_Time__c = Datetime.now();
            result.CreditSyncStatus__c = 'Pending';
            result.Status__c = event.Progress_Status__c == 'Cancelled' ? 'Cancelled' : (event.isSuccess__c ? 'Success' : 'Failed');
        }

        if (String.isNotBlank(event.Result_Data__c)) {
            result.Result_Data__c = event.Result_Data__c;
        }

        if (String.isNotBlank(event.Error_Message__c)) {
            result.Error_Message__c = event.Error_Message__c;
        }

        if (String.isNotBlank(event.Progress_Status__c)) {
            result.Progress_Status__c = event.Progress_Status__c;
        }

        return result;
    }

    private static Result__c clone(Result__c record) {
        return new Result__c(
            Id = record.Id,
            Test__c = record.Test__c,
            Status__c = record.Status__c,
            Job_Id__c = record.Job_Id__c,
            JobStep__c = record.JobStep__c,
            End_Time__c = record.End_Time__c,
            ParentId__c = record.ParentId__c,
            Job_Type__c = record.Job_Type__c,
            Function__c = record.Function__c,
            Start_Time__c = record.Start_Time__c,
            Result_Data__c = record.Result_Data__c,
            ApexCallback__c = record.ApexCallback__c,
            Error_Message__c = record.Error_Message__c,
            Progress_Status__c = record.Progress_Status__c,
            Function_Worker_Size__c = record.Function_Worker_Size__c,
            Custom_Function_Used_Minutes__c = record.Custom_Function_Used_Minutes__c,
            Custom_Function_Used_Credits__c = record.Custom_Function_Used_Credits__c
        );
    }
}