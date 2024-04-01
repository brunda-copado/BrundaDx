/**
 * @description Builds the payload for the Copado Function callout.
 * @exception throws JSONException. Make sure to handle it from the calling context.
 */
public with sharing class FunctionPayload {
    private String function;
    private String script;
    private String resultId;

    @TestVisible
    private String image;

    private List<Parameter> options;
    private List<Parameter> parameters;

    // CTOR

    public FunctionPayload(Function__c function) {
        this.function = function.API_Name__c;
        this.script = function.Script__c;
        this.image = imageName(function);
        this.options = options(function);
    }

    // PUBLIC

    public FunctionPayload options(List<Parameter> options) {
        if (options != null) {
            this.options.addAll(options);
        }

        return this;
    }

    public FunctionPayload parameters(List<Parameter> parameters) {
        this.parameters = parameters;
        return this;
    }

    public FunctionPayload resultId(String resultId) {
        this.resultId = resultId;
        return this;
    }

    /**
     * @exception throws Exception. Make sure to handle it from the calling context.
     */
    public FunctionPayload validate(String functionParams) {
        Map<String, String> parametersByName = asMap(parameters);
        List<Parameter> baseParams = (List<Parameter>) JSON.deserialize(functionParams, List<Parameter>.class);

        for (Parameter parameter : baseParams) {
            String value = parametersByName.get(parameter.name);

            if (isRequired(parameter) && String.isBlank(value)) {
                throw new CopadoFunctionException(String.format(Label.RequiredFunctionParameterMissing, new List<String> { parameter.name, function }));
            }
        }

        return this;
    }

    public String toJson() {
        overrideVolumeLimits();

        return JSON.serialize(this);
    }

    // PRIVATE

    private Boolean isRequired(Parameter parameter) {
        return (parameter.required != null ? Boolean.valueOf(parameter.required) : false);
    }

    private Map<String, String> asMap(List<Parameter> parameters) {
        Map<String, String> result = new Map<String, String>();

        for (Parameter parameter : parameters) {
            result.put(parameter.name, parameter.value);
        }

        return result;
    }

    private String imageName(Function__c function) {
        String result = null;

        if (String.isNotBlank(function.Image_Name__c)) {
            result = function.Image_Name__c;
        } else {
            throw new CopadoFunctionException(String.format(Label.FunctionImageDomainNotFound, new List<String> { function.API_Name__c }));
        }

        return result;
    }

    private List<Parameter> options(Function__c record) {
        List<Parameter> result = new List<Parameter>();

        if (String.isNotBlank(record.Options__c)) {
            result = (List<Parameter>) JSON.deserialize(record.Options__c, List<Parameter>.class);
        }

        if (String.isNotBlank(record.Worker_Size__c)) {
            result.add(new Parameter('workerSize', record.Worker_Size__c));
        }

        return result;
    }

    private void overrideVolumeLimits() {
        for (Parameter option : options) {
            if (option.name.equalsIgnoreCase('volumeSize')) {
                Decimal value = Decimal.valueOf(option.value);
                option.value = String.valueOf(Math.min(value, Settings.maximumVolumeSize));
            }

            if (option.name.equalsIgnoreCase('volumeTTL')) {
                Decimal value = Decimal.valueOf(option.value);
                option.value = String.valueOf(Math.min(Math.max(value, Settings.MIN_VOLUME_TTL), Settings.MAX_VOLUME_TTL));
            }
        }
    }
}