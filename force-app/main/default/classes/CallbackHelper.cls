public with sharing class CallbackHelper {
    @TestVisible
    private static String mockCallback;

    public static void executeCallback(Result__c result) {
        Logger.debug(result.Id, 'CallbackHelper.executeCallback', 'Callback Class: ', result.ApexCallback__c);
        Function__c function = new FunctionsSelector().byId(result.Function__c);

        try {
            functionCallback(function, result);
        } catch (Exception ex) {
            Logger.error(result.Id, 'functionCallback failed', '', null, ex);
            result = error(result, ex);
        }

        // Note: Result callback needs to be executed even if the function callback fails
        // This is important because other processes may be waiting for result callback(ex: Job Engine)
        try {
            resultCallback(function, result);
        } catch (Exception ex) {
            Logger.error(result.Id, 'resultCallback failed', '', null, ex);
            result = error(result, ex);
        }

        Logger.trace(result.Id, 'CallbackHelper.executeCallback exit', '', null);
    }

    public static void resultCallback(Function__c function, Id resultId, String status) {
        Result__c result = new ResultsSelector().byId(resultId);
        result.Status__c = status;

        resultCallback(function, result);
    }

    // PRIVATE

    private static void resultCallback(Function__c function, Result__c result) {
        if (String.isNotBlank(result.ApexCallback__c)) {
            apexCallback(result.ApexCallback__c).execute(function, result, result.Status__c);
        }
    }

    private static void functionCallback(Function__c function, Result__c result) {
        switch on function.Callback_Type__c {
            when 'ApexClass' {
                apexCallback(callbackName(function.ApexClass__c)).execute(function, result, result.Status__c);
            }
            when 'Flow' {
                try {
                    Map<String, Object> flowParameters = new Map<String, Object>{
                        'function' => function,
                        'result' => result,
                        'status' => result.Status__c
                    };
                    String callbackName = callbackName(function.FlowHandler__c);
                    Flow.Interview.createInterview(namespace(callbackName), localName(callbackName), flowParameters).start();
                } catch (Exception ex) {
                    throw new ApplicationException(
                        String.format(Label.Flow_Callback_Failed, new List<String>{ ex.getMessage(), ex.getStackTraceString() })
                    );
                }
            }
        }
    }

    private static String callbackName(String callback) {
        String result;

        if (Test.isRunningTest() && String.isNotBlank(mockCallback)) {
            result = mockCallback;
        } else if (String.isNotBlank(callback)) {
            result = callback;
        }

        return result;
    }

    private static MCCallBack apexCallback(String apexClass) {
        try {
            return ((MCCallBack) Type.forName(namespace(apexClass), localName(apexClass)).newInstance());
        } catch (Exception ex) {
            throw new ApplicationException(
                String.format(Label.Callback_not_Found, new List<String>{ Label.CallbackTypeApex, apexClass }) +
                ' ' +
                Label.Callback_not_Found_Information
            );
        }
    }

    private static String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private static String localName(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Result__c error(Result__c result, Exception ex) {
        result.Status__c = 'Failed';
        result.End_Time__c = Datetime.now();
        result.Progress_Status__c = Label.Error;
        result.Error_Message__c = String.format(Label.Function_Callback_Failed, new List<String>{ ex.getMessage() });

        Result__c updatedResult = (Result__c) Security.stripInaccessible(AccessType.UPDATABLE, new List<Result__c>{ result }).getRecords()[0];
        update updatedResult;

        return updatedResult;
    }
}