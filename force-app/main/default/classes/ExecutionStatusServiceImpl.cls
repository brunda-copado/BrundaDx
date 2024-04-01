public inherited sharing class ExecutionStatusServiceImpl {
    // PUBLIC

    public static Jobs.StatusResult execute(Id jobId) {
        if(jobId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Job Id'}));
        }

        Actions.StatusResult statusResult = StatusServiceImpl.status(jobId);

        return new Jobs.StatusResult(statusResult.jobStatus, statusResult.steps);
    }
}