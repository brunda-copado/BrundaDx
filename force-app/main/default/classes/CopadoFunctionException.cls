public virtual with sharing class CopadoFunctionException extends Exception {
    private String contextId;
    private Function__c function;
    public String resultId { get; private set; }

    public CopadoFunctionException function(Function__c function) {
        this.function = function;
        return this;
    }

    public CopadoFunctionException resultId(String resultId) {
        this.resultId = resultId;
        return this;
    }

    public CopadoFunctionException contextId(String contextId) {
        this.contextId = contextId;
        return this;
    }

    public CopadoFunctionException updateResult() {
        Result__c result = result();
        DML.safeUpsert(result, 'Could not create or update a Result object on a Function Exception ( CopadoFunctionException.updateResult class )');

        if (String.isBlank(resultId)) {
            resultId = result.Id;
        }

        return this;
    }

    public CopadoFunctionException updateContext() {
        if (objectType() == 'Deployment_Job__c') {
            Deployment_Job__c job = job();

            Deployment_Job__c jobToUpdate = new Deployment_Job__c(
                Id = job.Id,
                Status__c = 'Failed',
                Last_Result__c = resultId
            );
            DML.safeUpdate(jobToUpdate, 'Could not update the status for a Deployment Job object on a Function Exception ( CopadoFunctionException.updateContext class )');

            Result__c result = new Result__c(
                Id = resultId,
                Deployment__c = job.Step__r.Deployment__c
            );
            DML.safeUpdate(result, 'Could not update the context for a Result object on a Function Exception ( CopadoFunctionException.updateContext class )');
        }

        CallbackHelper.resultCallback(function, resultId, 'Error');

        return this;
    }

    private Deployment_Job__c job() {
        Deployment_Job__c job = [
            SELECT Status__c, Last_Result__c, Step__r.Deployment__c
            FROM Deployment_Job__c
            WHERE Id = :contextId
            WITH SECURITY_ENFORCED
        ];

        return job;
    }

    private Result__c result() {
        Id stepId = objectType() == 'JobStep__c' ? contextId : null;

        Result__c result = new Result__c(
            End_Time__c = Datetime.now(),
            Status__c = 'Failed',
            JobStep__c = stepId,
            Progress_Status__c = Label.Error,
            Error_Message__c = this.getMessage()
        );

        if (String.isBlank(resultId)) {
            result.Job_Type__c = function != null ? function.API_Name__c : SObjectType.Function__c.getLabel();
            result.Start_Time__c = Datetime.now();
            result.Function__c = function?.Id;
            result.ParentId__c = contextId;
        } else {
            result.Id = resultId;
        }

        return result;
    }

    private String objectType() {
        return String.isNotBlank(contextId) ? Id.valueOf(contextId).getSObjectType().getDescribe().getLocalName() : '';
    }
}