public with sharing class FindDuplicates {
    private sObject record;
    private Set<String> fields;
    private String objectType;

    // CTOR

    public FindDuplicates(sObject record, Set<String> fields) {
        this.record = record;
        this.fields = fields;
        this.objectType = record.getSObjectType().getDescribe(SObjectDescribeOptions.DEFAULT).getName();
    }

    // PUBLIC

    public List<sObject> execute() {
        List<String> filters = filters();
        List<sObject> result = new List<sObject>();

        if (objectType == Schema.SObjectType.Quality_Gate_Rule__c.getName()) {
            result = new QualityGateRulesSelector().byActiveMeetingAnyFilter(filters);
        } else if (objectType == Schema.SObjectType.Quality_Gate_Rule_Condition__c.getName()) {
            result = new QualityGateRuleConditionsSelector().byActiveMeetingAnyFilter(filters);
        }

        return result;
    }

    // PRIVATE

    private List<String> filters() {
        List<String> filters = new List<String>();

        for (String field : fields) {
            if (record.get(field) != null) {
                filters.add(asFilterCondition(field, String.valueOf(record.get(field))));
            } else{
                filters.add(field + ' = null');
            }
        }

        return filters;
    }

    private String asFilterCondition(String field, String value) {
        String result = '';

        switch on fieldType(field) {
            when MultiPicklist {
                result = multipicklistFilterCondition(field, value);
            }
            when else {
                result = stringFilterCondition(field, value);
            }
        }

        return result;
    }

    private String multipicklistFilterCondition(String field, String value) {
        String result = '';

        if (value.contains(';')) {
            String[] values = value.split(';');
            result = '(';
            for (Integer index = 0; index < values.size(); index++) {
                result += index > 0 ? ' OR ' : '';
                result += field + ' INCLUDES (\'' + String.escapeSingleQuotes(values[index]) + '\')';
            }
            result += ')';
        } else {
            result = field + ' INCLUDES (\'' + String.escapeSingleQuotes(value) + '\')';
        }

        return result;
    }

    private String stringFilterCondition(String field, String value) {
        String result = '';

        if (field == Schema.SObjectType.Quality_Gate_Rule__c.fields.Id.getName() 
            || field == Schema.SObjectType.Quality_Gate_Rule_Condition__c.fields.Id.getName()) {
            result = field + ' != \'' + String.escapeSingleQuotes(value) + '\'';
        } else {
            result = field + ' = \'' + String.escapeSingleQuotes(value) + '\'';
        }

        return result;
    }

    private Schema.DisplayType fieldType(String fieldName) {
        SObjectType sObjectTypeInstance = ((SObject) (Type.forName('Schema.' + objectType).newInstance())).getSObjectType();
        DescribeSObjectResult describeResult = sObjectTypeInstance.getDescribe(SObjectDescribeOptions.DEFAULT);
        return describeResult.fields.getMap().get(fieldName).getDescribe().getType();
    }
}