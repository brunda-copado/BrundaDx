@RestResource(urlMapping='/clioperations/*')
global with sharing class CliProxy {
    private static final Map<String, Type> SERVICE_BY_COMMAND = new Map<String, Type>{
        'auth:grant' => AuthGrantService.class,

        'work:set' => WorkSetService.class,
        'work:push' => WorkPushServices.class,
        'work:submit' => WorkSubmitService.class,

      	'pipeline:connection:create' => PipelineConnectionCreateService.class,

        'package:import' => PackageImportService.class,
        'package:version:create' => PackageVersionCreateService.class,
        'job:status' => JobStatusService.class
    };

    private static CLIInterface cliInterface;

    @HttpPost
    global static String doPost() {
        String result = null;

        try {
            CliSecurityService.checkValidity();
            CLIWrapper request = (CLIWrapper) JSON.deserialize(RestContext.request.requestBody.toString(), CLIWrapper.class);

            result = initializeService(request).run(request);
        }
        catch (Exception ex) {
            result = JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), ex.getMessage()));
        }

        return result;
    }

    /**
     * Strategy pattern
     * Different services will be initialised by using CLIInterface based on requested root
     * @see CLIInterface
     */
    private static CLIInterface initializeService(CLIWrapper request) {
        String command = request.mainService + ':' + request.subService;

        if (SERVICE_BY_COMMAND.containsKey(command)) {
            return (CLIInterface) (SERVICE_BY_COMMAND.get(command).newInstance());
        }
        else if (SERVICE_BY_COMMAND.containsKey(command + ':' + request.operation)) {
            return (CLIInterface) (SERVICE_BY_COMMAND.get(command + ':' + request.operation).newInstance());
        }
        else {
            throw new CliException(Label.UnSupportedOperation);
        }
    }

    /**
     * Wrapper class to deserialize JSON coming from CLI calls
     */
    public class CLIWrapper {
        public String mainService;
        public String subService;
        public String operation;
        public String body;
    }
}