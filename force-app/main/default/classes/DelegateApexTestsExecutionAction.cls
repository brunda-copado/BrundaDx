public with sharing class DelegateApexTestsExecutionAction {
    public with sharing class Request {
        @InvocableVariable(label='Test Class Names')
        public String testClassNames;

        @InvocableVariable(label='Org Credential Id')
        public String credentialId;
    }

    public with sharing class Result {
        @InvocableVariable(label='Async Job Id')
        public String asyncJobId;
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        public Result(String asyncJobId, Boolean isSuccess) {
            this.asyncJobId = asyncJobId;
            this.isSuccess = isSuccess;
        }
    }

    // PUBLIC

    @InvocableMethod(label='Delegate Apex Tests Execution' description='Delegate Apex Tests Execution to the specific org credential' category='Test')
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        try {
            Request request = requests[0];

            String asyncJobId = new ApexTestsService(request.credentialId).delegateRun(request.testClassNames);

            results.add(new Result(asyncJobId, true));
        } catch (Exception ex) {
            results.add(new Result('', false));
        }

        return results;
    }
}