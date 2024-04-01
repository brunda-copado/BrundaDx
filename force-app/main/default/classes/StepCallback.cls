public with sharing class StepCallback {

    // PUBLIC

    public Id execute(Id jobId, OnJobStepComplete.EventPayload payload) {
        Logger.trace(jobId, 'StepCallback.execute', 'Payload: ', payload);
        Id result = null;

        if(payload.isSuccess) {
            result = new JobEngine(jobId).executeNextStep();
        } else {
            String status = 'Error';
            if(payload.status() == 'Cancelled') {
                status = 'Canceled';
            }
            new JobEngine(jobId).finish(status, payload.errorMessage);
        }

        return result;
    }
}