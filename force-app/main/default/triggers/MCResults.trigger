trigger MCResults on MC_Result__e(after insert) {
    new HandleBackendResponse(Trigger.new).execute();
}