@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class Logger {

    @TestVisible
    // Note: Set it to true iff logger needs to run in test class
    private static Boolean publishEventsDuringTests = false;
    public static LOGGING_LEVEL minimumLogLevel {
        get {
            if (minimumLogLevel == null) {
                Integer loggingLevel = (Integer) Personal_Settings__c.getInstance()?.Minimum_Logging_Level__c;
                loggingLevel = (loggingLevel == null || loggingLevel > 4) ? 3 : loggingLevel;
                return LOGGING_LEVEL.values().get(loggingLevel);
            }
            return minimumLogLevel;
        }
    }

    private enum LOGGING_LEVEL {
        TRACE,      // 0
        DEBUG,      // 1
        INFO,       // 2
        WARNING,    // 3
        ERROR       // 4
    }

    // PUBLIC

    /**
     * Log Level 0
     */
    public static void trace(String genericId, String section, String message, Object value) {
        emit(LOGGING_LEVEL.TRACE, genericId, section, message, value, null);
    }

    /**
     * Log Level 1
     */
    public static void debug(String genericId, String section, String message, Object value) {
        emit(LOGGING_LEVEL.DEBUG, genericId, section, message, value, null);
    }

    /**
     * Log Level 2
     */
    public static void info(String genericId, String section, String message, Object value) {
        emit(LOGGING_LEVEL.INFO, genericId, section, message, value, null);
    }

    /**
     * Log Level 3
     */
    public static void warning(String genericId, String section, String message, Object value) {
        emit(LOGGING_LEVEL.WARNING, genericId, section, message, value, null);
    }

    /**
     * Log Level 4
     */
    public static void error(String genericId, String section, String message, Object value, Exception ex) {
        emit(LOGGING_LEVEL.ERROR, genericId, section, message, value, ex);
    }

    public static void logRecords(List<Logger_Event__e> events) {
        List<Result__c> result = new List<Result__c>();

        for (Logger_Event__e evt : events) {
            result.add(
                new Result__c(
                    Job_Type__c = 'Logger',
                    Start_Time__c = evt.CreatedDate,
                    OwnerId = evt.User_Id__c,
                    Job_Id__c = evt.Generic_Id__c,
                    Progress_Status__c = evt.Section__c,
                    Description__c = evt.Limits_Usage__c,
                    ParentId__c = evt.Log_Level__c,
                    Result_Data__c = evt.Payload__c,
                    Error_Code__c = evt.Log_Level__c,
                    Error_Message__c = evt.Exception_Details__c,
                    Status__c = evt.Log_Level__c == LOGGING_LEVEL.ERROR.name() ? 'Failed' : 'Success'
                )
            );
        }

        List<Database.SaveResult> saveResult = Database.insert(result, false);

        for (Database.SaveResult sr : saveResult) {
            if (!sr.isSuccess()) {
                System.debug(LoggingLevel.FINEST, 'Error Creating Logger Result: ' + sr.getErrors());
            }
        }
    }

    // PRIVATE

    private static void emit(
        LOGGING_LEVEL logLevel,
        String genericId,
        String section,
        String message,
        Object value,
        Exception ex
    ) {
        System.debug(LoggingLevel.FINEST, 'Logger.Log: ' + genericId + ' ' + section + ' ' + logLevel + ' ' + message);

        try {
            if (canPublishEvent() && isAboveMinimum(logLevel)) {
                Logger_Event__e logEvent = new Logger_Event__e();
                logEvent.User_Id__c = UserInfo.getUserId();
                logEvent.Generic_Id__c = String.isBlank(genericId) ? Request.getCurrent().getRequestId() : genericId.abbreviate(255);
                logEvent.Section__c = section?.abbreviate(255);
                logEvent.Log_Level__c = logLevel.name();
                logEvent.Limits_Usage__c = usage().abbreviate(32768);
                logEvent.Exception_Details__c = formatException(ex)?.abbreviate(32768);
                logEvent.Payload__c = formatPayload(message, value)?.abbreviate(131072);

                EventBus.publish(logEvent);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.FINEST, 'Error Creating Logs: ' + e.getMessage());
        }
    }

    
    private static Boolean canPublishEvent() {
        return !Test.isRunningTest() || publishEventsDuringTests;
    }

    
    private static Boolean isAboveMinimum(LOGGING_LEVEL logLevel) {
        return logLevel.ordinal() >= minimumLogLevel.ordinal();
    }


    private static String usage() {
        return JSON.serialize(
            new Map<String, Object>{
                'User' => UserInfo.getUserName(),
                'Quiddity:' => Request.getCurrent().getQuiddity(),
                'RequestId:' => Request.getCurrent().getRequestId(),
                'DMLRows:' => Limits.getDmlRows(),
                'DMLs:' => Limits.getDmlStatements(),
                'QueryRows:' => Limits.getQueryRows(),
                'LocatorRows:' => Limits.getQueryLocatorRows(),
                'Callouts:' => Limits.getCallouts(),
                'FutureCalls:' => Limits.getFutureCalls(),
                'CpuTime:' => Limits.getCpuTime(),
                'HeapSize:' => Limits.getHeapSize(),
                'Queries:' => Limits.getQueries(),
                'QueueableJobs:' => Limits.getQueueableJobs(),
                'ImmediateDML:' => Limits.getPublishImmediateDML(),
                'DailyStreamingApiEvents:' => OrgLimits.getMap().get('DailyStreamingApiEvents').getValue()
            }
        );
    }


    private static String formatException(Exception ex) {
        return ex == null
            ? ''
            : 'Error occured at line: ' +
              ex.getLineNumber() +
              '\nError Message: ' +
              ex.getMessage() +
              '\nStack Trace:\n' +
              ex.getStackTraceString() +
              '\n\nException: ' +
              ex;
    }

    
    private static String formatPayload(String message, Object value) {
        return (message + '\n' + value);
    }
}