public with sharing class PackageVersionCreateService implements CLIInterface {
    // PUBLIC

    public String run(CliProxy.CLIWrapper cliRequest) {
        try {
            PackageVersionCreateAction.Request request = asRequest(cliRequest.body);
            PackageVersionCreateAction.Response response = new PackageVersionCreateAction(request).create();

            return new Response(CliSfDataWrapper.StatusResult.OK.name(), 'Package Version creation started successfully.', response)
                .serialize();
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }

    private PackageVersionCreateAction.Request asRequest(String requestBody) {
        return (PackageVersionCreateAction.Request) JSON.deserialize(requestBody, PackageVersionCreateAction.Request.class);
    }

    // INNER

    @TestVisible
    private class Response extends CliSfDataWrapper {
        @TestVisible
        private PackageVersionCreateAction.Response body;

        public Response(String status, String message, PackageVersionCreateAction.Response job) {
            this.body = job;
            this.status = status;
            this.message = message;
        }

        public String serialize() {
            return JSON.serialize(this, true);
        }
    }
}