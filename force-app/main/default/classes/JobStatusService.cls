public with sharing class JobStatusService implements CLIInterface {

    // PUBLIC

    public String run(CliProxy.CLIWrapper cliRequest) {
        CheckStatusAction.Request request = asRequest(cliRequest.body);
        List<CheckStatusAction.Response> response = CheckStatusAction.fetch(
            new List<CheckStatusAction.Request>{ request }
        );

        return new Response(CliSfDataWrapper.StatusResult.OK.name(), 'Job Status', response[0])
                    .serialize();
    }

    // PRIVATE

    private CheckStatusAction.Request asRequest(String requestBody) {
        return (CheckStatusAction.Request) JSON.deserialize(requestBody, CheckStatusAction.Request.class);
    }

    // INNER

    @TestVisible
    private class Response extends CliSfDataWrapper {
        @TestVisible
        private CheckStatusAction.Response body;

        public Response(String status, String message, CheckStatusAction.Response body) {
            this.body = body;
            this.status = status;
            this.message = message;
        }

        public String serialize() {
            return JSON.serialize(this);
        }
    }
}