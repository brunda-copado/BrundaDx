@SuppressWarnings('PMD.CyclomaticComplexity')
public inherited sharing class FunctionEngine implements Queueable, Database.AllowsCallouts {
    private final String apiName;

    private String contextId;
    private Result__c result;
    private Function__c function;
    private String resultCallback;
    private List<Parameter> options;
    private Boolean showValidationErrors = false;
    private List<Parameter> parameters = new List<Parameter>();
    private Map<String, Parameter> inputParametersByName = new Map<String, Parameter>();

    @TestVisible
    private static MC_Result__e mockResponse;

    // CONSTRUCTOR

    public FunctionEngine(String apiName) {
        this.apiName = apiName;
    }

    // PUBLIC

    public FunctionEngine contextId(String contextId) {
        this.contextId = contextId;
        return this;
    }

    public FunctionEngine parameters(List<Parameter> parameters) {
        if (parameters != null) {
            for (Parameter parameter : parameters) {
                inputParametersByName.put(parameter.name, parameter);
            }
        }

        return this;
    }

    public FunctionEngine options(List<Parameter> options) {
        this.options = options;
        return this;
    }

    public FunctionEngine resultCallback(String resultCallback) {
        this.resultCallback = resultCallback;
        return this;
    }

    public FunctionEngine showValidationErrors(Boolean showValidationErrors) {
        this.showValidationErrors = showValidationErrors;
        return this;
    }

    public Id execute() {
        validateAccess();
        try {
            Logger.info(contextId, 'FunctionEngine.execute()', '', null);

            function = new FunctionsSelector().byApiName(apiName);
            createResult();
            validateFunction();

            if (String.isNotBlank(function.Parameters__c)) {
                parameters = (List<Parameter>) JSON.deserialize(function.Parameters__c, List<Parameter>.class);
            }

            for (Parameter parameter : parameters) {
                if (inputParametersByName.containsKey(parameter.name)) {
                    Parameter inputParameter = inputParametersByName.get(parameter.name);
                    parameter.value = String.isBlank(inputParameter.value) ? inputParameter.defaultValue : inputParameter.value;
                } else if (String.isBlank(parameter.value)) {
                    parameter.value = parameter.defaultValue;
                }
            }

            if (Test.isRunningTest() && mockResponse != null) {
                onCompleteMock();
            } else {
                checkCredits();
                checkParallelLimit();
                System.enqueueJob(this);
            }
        } catch (Exception ex) {
            Logger.warning(contextId, 'FunctionEngine.execute', '', null);
            CopadoFunctionException error = error(ex);

            if (showValidationErrors) {
                throw error;
            }
        }

        return result.Id;
    }

    public void execute(QueueableContext ctx) {
        try {
            if (!parameters.isEmpty()) {
                parameters = new TemplatingEngine(contextId, parameters).parse();
            }
            new FunctionCallout(result.Id).isStandard(function.Type__c == 'Standard').payload(payload()).apiKey(apiKey()).build().request().parseResponse();
        } catch (Exception ex) {
            Logger.error(result.Id, 'FunctionEngine.execute(ctx)', 'Parameters: ', parameters, ex);
            error(ex);
        }
    }

    // PRIVATE

    private void checkParallelLimit() {
        Integer functionParallelLimit = FeatureManagement.checkPackageIntegerValue('Function_Parallel_Limit');

        if (functionsInProgress() > functionParallelLimit) {
            throw new CopadoFunctionException(
                String.format(Label.functionParallelLimitError, new List<String>{ String.valueOf(functionParallelLimit) })
            );
        }
    }

    private Integer functionsInProgress() {
        return [
            SELECT COUNT()
            FROM Result__c
            WHERE Status__c IN ('Not Started', 'In Progress') AND Function__c != NULL AND SystemModstamp >= LAST_N_DAYS:1
            WITH SECURITY_ENFORCED
        ];
    }

    private void checkCredits() {
        if (FunctionCreditHelper.hardLimitReached()) {
            throw new CopadoFunctionException(Label.Function_Credit_Limit_Exceeded);
        }
    }

    private void validateFunction() {
        if (function == null) {
            throw new CopadoFunctionException(Label.Function_not_Found + ' ' + apiName);
        }
        if (String.isBlank(function.Script__c)) {
            throw new CopadoFunctionException(Label.Script_Cannot_Be_Empty);
        }
    }

    private void validateAccess() {
        if(!Utilities.checkPermission('Copado_Functions', new Set<Id>{ UserInfo.getUserId() }, false) &&
            !Utilities.checkPermission('Copado_Functions_User', new Set<Id>{ UserInfo.getUserId() }, false)) {
            throw new ApplicationException(String.format(Label.PermissionSet_InsufficientAccess, new List<String> {'Copado Functions Admin/Copado Functions User'}));
        }
    }

    private String payload() {
        return new FunctionPayload(function).parameters(parameters).options(options).validate(function.Parameters__c).resultId(result.Id).toJson();
    }

    private void createResult() {
        Id stepId = String.isNotBlank(contextId)
            ? Id.valueOf(contextId).getSObjectType().getDescribe().getLocalName() == 'JobStep__c' ? contextId : null
            : null;

        result = new Result__c(
            JobStep__c = stepId,
            ParentId__c = contextId,
            Status__c = 'Not Started', // TODO: initial status should be Not Started. Carefully review all test classes for this change.
            Job_Type__c = String.isNotBlank(apiName) ? apiName : SObjectType.Function__c.getLabel(),
            ApexCallback__c = resultCallback,
            Function__c = function?.Id,
            Timeout__c = function?.Timeout__c,
            Function_Worker_Size__c = function?.Worker_Size__c
        );

        DML.safeInsert(result, 'Could not create a Result object for the Function execution ( FunctionEngine.createResult class )');
    }

    private String apiKey() {
        String result;

        if (SObjectType.Personal_Settings__c.fields.API_Key__c.isAccessible()) {
            result = new Settings().mySettings.API_Key__c;
        }

        if (String.isBlank(result)) {
            throw new CopadoFunctionException(String.format(Label.APIKeyNotFound, new List<String>{ UserInfo.getName() }));
        }

        return result;
    }

    private CopadoFunctionException error(Exception ex) {
        // needed for ease of internal troubleshooting when an error occurs in a subscriber org.
        System.debug(LoggingLevel.ERROR, 'error: ' + ex.getMessage() + ': ' + ex.getStackTraceString());

        CopadoFunctionException error = new CopadoFunctionException(ex.getMessage())
            .resultId(result?.Id)
            .contextId(contextId)
            .function(function)
            .updateResult()
            .updateContext();

        return error;
    }

    // TEST MOCK

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void onCompleteMock() {
        Id stepId = String.isNotBlank(contextId)
            ? Id.valueOf(contextId).getSObjectType().getDescribe().getLocalName() == 'JobStep__c' ? contextId : null
            : null;

        if (stepId != null) {
            update new JobStep__c(Id = stepId, Result__c = result.Id);
        }

        FunctionWebEvent.doPost(
            result.Id,
            'Completed',
            mockResponse.Error_Message__c,
            String.isNotBlank(mockResponse.Result_Data__c)
                ? mockResponse.Result_Data__c
                : JSON.serialize(this.options), // this is the only way to send the options to the testing mock in order to validate the killVolume option,
            mockResponse.IsFinished__c,
            mockResponse.isSuccess__c
        );
    }
}