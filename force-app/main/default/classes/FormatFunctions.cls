public with sharing class FormatFunctions {
    private static final Pattern namePattern = Pattern.compile('[a-zA-Z_][a-zA-Z0-9_]*');
    private List<Function__c> records;

    // CONSTRUCTOR

    public FormatFunctions(List<Function__c> records) {
        this.records = records;
    }

    // PUBLIC

    public void jsonFields() {
        for (Function__c function : records) {
            validate(function.Parameters__c, function);

            function.Options__c = serializePretty(function.Options__c);
            function.Parameters__c = serializePretty(function.Parameters__c);
        }
    }

    // PRIVATE

    private String serializePretty(String parameterString) {
        return JSON.serializePretty(parameters(parameterString), true);
    }

    private List<Parameter> parameters(String parameterString) {
        List<Parameter> result = new List<Parameter>();

        if (String.isNotBlank(parameterString)) {
            result = (List<Parameter>) JSON.deserialize(parameterString, List<Parameter>.class);
        }

        return result;
    }

    private void validate(String parameterString, Function__c function) {
        for (Parameter parameter : parameters(parameterString)) {
            if (!namePattern.matcher(parameter.name).matches()) {
                function.addError(String.format(Label.InvalidNameformat, new List<String>{ parameter.name }));
            }
        }
    }
}