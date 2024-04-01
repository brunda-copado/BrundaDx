trigger LoggerEventsTrigger on Logger_Event__e(after insert) {
    Logger.logRecords(Trigger.new);
}