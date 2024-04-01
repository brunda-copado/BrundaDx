public with sharing class DataFiltersCtrl {
    private static final Set<String> INVALID_TYPES = new Set<String>{ 'ADDRESS' };

    @AuraEnabled(cacheable=true)
    public static List<Field> retrieveFields(Id orgCredentialId, String objectName) {
        try {
            List<DescribeSObjectService.CopadoField> fields = getFieldsDescribe(orgCredentialId, objectName);
            return convertFields(fields);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Field> parseFields(String fieldsDescribe) {
        try {
            List<DescribeSObjectService.CopadoField> fields = (List<DescribeSObjectService.CopadoField>) JSON.deserialize(
                fieldsDescribe,
                List<DescribeSObjectService.CopadoField>.class
            );
            return convertFields(fields);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    public static List<Field> convertFields(List<DescribeSObjectService.CopadoField> fields) {
        List<Field> result = new List<Field>();

        for (DescribeSObjectService.CopadoField field : fields) {
            if (!INVALID_TYPES.contains(field.type.toUpperCase())) {
                result.add(new Field(field));
            }
        }

        result.sort();

        if (result.isEmpty()) {
            throw new ApplicationException(Label.Error_Getting_Object_Fields);
        }
        return result;
    }

    private static List<DescribeSObjectService.CopadoField> getFieldsDescribe(Id orgCredentialId, String objectName) {
        DescribeSObjectService.DescribeResponse response = new DescribeSObjectService(orgCredentialId).getFields(objectName);
        return response?.fields != null ? response.fields : new List<DescribeSObjectService.CopadoField>();
    }

    public with sharing class Field implements Comparable {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public List<Operator> operators;

        public Field(DescribeSObjectService.CopadoField copadoField) {
            this.label = copadoField.label;
            this.name = copadoField.name;
            this.type = copadoField.type.toUpperCase();
            this.operators = typeOperators(this.type);
            this.operators.sort();
        }

        private List<Operator> typeOperators(String type) {
            List<Operator> operators = new List<Operator>();

            Map<String, String[]> operatorCodesByFieldType = OperatorTypeCodes.getTypeToOps();
            Map<String, String> operatorLabelByCode = OperatorTypeCodes.getOperatorCodes();
            Map<String, String> comparisonOperatorByCode = OperatorTypeCodes.getOperatorSembols();

            if (operatorCodesByFieldType.containsKey(type)) {
                List<String> operatorCodes = operatorCodesByFieldType.get(type);
                for (String code : operatorCodes) {
                    Operator operator = new Operator();
                    operator.code = code;
                    if (operatorLabelByCode.containsKey(code)) {
                        operator.label = operatorLabelByCode.get(code);
                    }
                    // do not add operator if comparison operator is not defined
                    if (comparisonOperatorByCode.containsKey(code)) {
                        operators.add(operator);
                    }
                }
            }

            return operators;
        }

        public Integer compareTo(Object compareTo) {
            Field compareToField = (Field) compareTo;
            return label.compareTo(compareToField.label);
        }
    }

    public with sharing class Operator implements Comparable {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String code;

        public Integer compareTo(Object compareTo) {
            Operator compareToOperator = (Operator) compareTo;
            return label.compareTo(compareToOperator.label);
        }
    }
}