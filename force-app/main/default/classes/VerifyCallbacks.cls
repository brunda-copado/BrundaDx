@SuppressWarnings('PMD')
public with sharing class VerifyCallbacks {
    private final String APEX_CLASS = 'ApexClass';
    private final String FLOW = 'Flow';
    private List<Function__c> records;
    private Set<String> classNames = new Set<String>();
    private Set<String> flowNames = new Set<String>();
    private Set<String> namespaces = new Set<String>();

    // CONSTRUCTOR

    public VerifyCallbacks(List<Function__c> records) {
        this.records = records;
    }

    public VerifyCallbacks(List<Function__c> records, Map<Id, Function__c> old) {
        this.records = updatedRecords(records, old);
    }

    // PUBLIC

    public void execute() {
        setCallbacks();
        checkErrors(selectClasses(), selectFlows());
    }

    // PRIVATE

    private List<Function__c> updatedRecords(List<Function__c> records, Map<Id, Function__c> old) {
        List<Function__c> result = new List<Function__c>();

        for (Function__c record : records) {
            String callbackType = record.Callback_Type__c;

            Function__c oldRecord = old.get(record.Id);
            if (callbackType == APEX_CLASS && record.ApexClass__c != oldRecord.ApexClass__c && String.isNotBlank(record.ApexClass__c)) {
                result.add(record);
            } else if (callbackType == FLOW && record.FlowHandler__c != oldRecord.FlowHandler__c && String.isNotBlank(record.FlowHandler__c)) {
                result.add(record);
            }
        }

        return result;
    }

    private void setCallbacks() {
        for (Function__c record : records) {
            String callbackType = record.Callback_Type__c;

            if (callbackType == APEX_CLASS && String.isNotBlank(record.ApexClass__c)) {
                classNames.add(localName(record.ApexClass__c));
                String namespace = namespace(record.ApexClass__c);
                if (String.isNotBlank(namespace)) {
                    namespaces.add(namespace);
                }
            } else if (callbackType == FLOW && String.isNotBlank(record.FlowHandler__c)) {
                flowNames.add(localName(record.FlowHandler__c));
                String namespace = namespace(record.FlowHandler__c);
                if (String.isNotBlank(namespace)) {
                    namespaces.add(namespace);
                }
            }
        }
    }

    private void checkErrors(Set<String> classes, Set<String> flows) {
        for (Function__c record : records) {
            String callbackType = record.Callback_Type__c;

            Schema.DescribeFieldResult fieldDescribe = Function__c.sObjectType.getDescribe()
                .fields.getMap()
                .get(Settings.ns + 'Callback_Type__c')
                .getDescribe();

            Map<String, String> picklistLabelsPerValue = new Map<String, String>();
            for (Schema.PicklistEntry picklistEntry : fieldDescribe.getPicklistValues()) {
                picklistLabelsPerValue.put(picklistEntry.getValue(), picklistEntry.getLabel());
            }

            if (callbackType == APEX_CLASS && String.isNotBlank(record.ApexClass__c)) {
                if (!classes.contains(record.ApexClass__c)) {
                    addError(record, picklistLabelsPerValue.get(callbackType), record.ApexClass__c);
                }
            } else if (callbackType == FLOW && String.isNotBlank(record.FlowHandler__c)) {
                if (!flows.contains(record.FlowHandler__c)) {
                    addError(record, picklistLabelsPerValue.get(callbackType), record.FlowHandler__c);
                }
            }
        }
    }

    private Set<String> selectClasses() {
        Set<String> result = new Set<String>();
        String query = 'SELECT Name, NamespacePrefix FROM ApexClass WHERE Name IN :classNames AND Status = \'Active\' {0}';

        for (ApexClass record : Database.query(String.format(query, new List<String>{ namespaceFilter() }))) {
            String name = (String.isNotBlank(record.NamespacePrefix) ? record.NamespacePrefix + '.' : '') + record.Name;
            result.add(name);
        }

        return result;
    }

    private Set<String> selectFlows() {
        Set<String> result = new Set<String>();
        String query = 'SELECT ApiName, NamespacePrefix FROM FlowDefinitionView WHERE ApiName IN :flowNames AND IsActive = true {0}';

        for (FlowDefinitionView record : Database.query(String.format(query, new List<String>{ namespaceFilter() }))) {
            String name = (String.isNotBlank(record.NamespacePrefix) ? record.NamespacePrefix + '.' : '') + record.ApiName;
            result.add(name);
        }

        return result;
    }

    private String namespaceFilter() {
        return !namespaces.isEmpty() ? ' AND NamespacePrefix IN :namespaces' : '';
    }

    private String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private String localName(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

    private void addError(Function__c record, String callbackType, String handlerName) {
        record.addError(String.format(Label.Callback_not_Found, new List<String>{ callbackType, handlerName }));
    }
}