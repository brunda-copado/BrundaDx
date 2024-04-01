public with sharing class FunctionResultMonitor implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public static final Integer BATCH_SIZE = 10;
    private static final Datetime NOW = Datetime.now();
    public static final Integer COMMUNICATION_TIMEOUT = Test.isRunningTest() ? 1 : timeout();
    private final String apiKey;
    private enum TIMEOUT_TYPES {
        COMMUNICATION,
        EXECUTION
    }

    // CONSTRUCTOR

    public FunctionResultMonitor() {
        apiKey = new Settings().mySettings.API_Key__c;
    }

    // PUBLIC

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query());
    }

    public void execute(Database.BatchableContext context, List<Result__c> results) {
        List<MC_Result__e> events = new List<MC_Result__e>();

        for (Result__c result : results) {
            TIMEOUT_TYPES timeoutType = timeoutType(result);

            if (timeoutType != null) {
                CopadoFunctions.cancel(result.Id);
                events.add(event(result, timeoutType));
            }
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
            runOnComplete(events);
        }
    }


    public void finish(Database.BatchableContext context) {
        Database.executeBatch(new FunctionCreditHelper());
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    public static void schedule() {
        try {
            System.scheduleBatch(new FunctionResultMonitor(), 'FunctionResultMonitor', COMMUNICATION_TIMEOUT, BATCH_SIZE);
        } catch (Exception error) {
            // silently fail. No need to handle error since it will fail most of the time.
        }
    }

    // PRIVATE

    private String query() {
        // system mode, no need to enforce security checks.
        return 'SELECT LastModifiedDate, Status__c, Progress_Status__c, Start_Time__c, Timeout__c, Function__c,' +
            ' Function__r.API_Name__c, Function__r.Script__c, Function__r.Image_Name__c, Function__r.Worker_Size__c' +
            ' FROM Result__c WHERE Status__c IN (\'Not Started\', \'In Progress\') AND Function__c != null LIMIT 1000';
    }


    // important note: batch size must remain low because there are DML/query operations inside FunctionWebEvent.doPost().
    // To be reviewed with architects.
    private void runOncomplete(List<MC_Result__e> events) {
        Boolean updateCredits = FunctionWebEvent.updateCredits;
        FunctionWebEvent.updateCredits = false;

        for (MC_Result__e event : events) {
            FunctionWebEvent.doPost(
                event.ResultId__c,
                event.Progress_Status__c == 'Cancelled' ? 'Cancelled' : 'Failed',
                event.Error_Message__c,
                event.Result_Data__c,
                event.IsFinished__c,
                event.IsSuccess__c
            );
        }

        FunctionWebEvent.updateCredits = updateCredits;
    }

    @TestVisible
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static Integer timeout() {
        Integer result = 5; // default communication timeout in minutes

        try {
            String defaultTimeout = defaultTimeout();

            if (String.isNotBlank(defaultTimeout)) {
                result = Integer.valueOf(defaultTimeout);
            }
        } catch (Exception ex) {
            // no action required. If query fails, return default timeout.
        }

        return result;
    }

    private static String defaultTimeout() {
        return [SELECT Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = 'Functions_backend_communication_timeout' WITH SECURITY_ENFORCED]
        ?.Text_Field__c;
    }

    private TIMEOUT_TYPES timeoutType(Result__c record) {
        TIMEOUT_TYPES result;

        if (secondsElapsed(record.LastModifiedDate) > seconds(COMMUNICATION_TIMEOUT)) {
            result = TIMEOUT_TYPES.COMMUNICATION;
        } else if (timeFieldsNotEmpty(record) && secondsElapsed(record.Start_Time__c) > seconds(record.Timeout__c)) {
            result = TIMEOUT_TYPES.EXECUTION;
        }

        return result;
    }

    private Boolean timeFieldsNotEmpty(Result__c record) {
        return record.Start_Time__c != null && record.Timeout__c != null;
    }

    private Long secondsElapsed(Datetime startTime) {
        Long milliseconds = NOW.getTime() - startTime.getTime();
        Long seconds = milliseconds / 1000;
        return seconds;
    }

    private MC_Result__e event(Result__c result, TIMEOUT_TYPES timeoutType) {
        return new MC_Result__e(
            ResultId__c = result.Id,
            isFinished__c = true,
            isSuccess__c = false,
            Progress_Status__c = Label.Cancelled,
            Error_Message__c = errorMessage(result, timeoutType)
        );
    }

    private String errorMessage(Result__c result, TIMEOUT_TYPES timeoutType) {
        return String.format(Label.Function_Execution_Timed_Out, new List<String>{ String.valueOf(timeoutMinutes(result, timeoutType)) }) +
            ' ' +
            Label.Function_Cancelled;
    }

    private Integer timeoutMinutes(Result__c result, TIMEOUT_TYPES timeoutType) {
        Integer timeoutMinutes;

        switch on timeoutType {
            when COMMUNICATION {
                timeoutMinutes = COMMUNICATION_TIMEOUT;
            }
            when EXECUTION {
                timeoutMinutes = result.Timeout__c != null ? Integer.valueOf(result.Timeout__c) : 0;
            }
        }

        return timeoutMinutes;
    }

    private Decimal seconds(Decimal minutes) {
        return minutes == null ? 0 : minutes * 60;
    }
}