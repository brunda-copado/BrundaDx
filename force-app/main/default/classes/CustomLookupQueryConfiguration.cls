public with sharing class CustomLookupQueryConfiguration {
    private static final Map<String, AdditionalFilter> ADDITIONAL_FILTERS = new Map<String, AdditionalFilter>{
        'AutomationTemplateFilter' => new AutomationTemplateFilter(),
        'RegularGroupsFilter' => new RegularGroupsFilter(),
        'TestScriptTitleFilter' => new TestScriptTitleFilter(),
        'ActiveUserFilter' => new ActiveUserFilter(),
        'PreviousReleaseFilter' => new PreviousReleaseFilter(),
        'CrtTest' => new CrtTestFilter()
    };

    private String queryTemplate = 'SELECT {0} FROM {1} WHERE {2} LIKE \'\'{3}\'\' {4} WITH SECURITY_ENFORCED LIMIT 10';

    @AuraEnabled
    public String searchField {
        get {
            if (searchField != null) {
                searchField = String.escapeSingleQuotes(searchField);
            }
            return searchField;
        }
        set;
    }
    @AuraEnabled
    public String objectName { get; set; }
    @AuraEnabled
    public String searchKey {
        get {
            if (searchKey != null) {
                searchKey = String.format('%{0}%', new List<String>{ String.escapeSingleQuotes(searchKey) });
            }
            return searchKey;
        }
        set;
    }
    @AuraEnabled
    public String extraFilterType { get; set; }
    @AuraEnabled
    public List<Object> filterFormattingParameters { get; set; }
    @AuraEnabled
    public List<String> additionalFields { get; set; }

    // PUBLIC

    public String getFormattedQuery() {
        List<Object> formatParams = getFormatParams();
        String query = String.format(queryTemplate, formatParams);
        return query;
    }

    // PRIVATE

    private List<Object> getFormatParams() {
        String fieldsToRetrieve = (additionalFields != null && !additionalFields.isEmpty())
            ? searchField + ',' + String.join(additionalFields, ',')
            : searchField;

        List<Object> result = new List<Object>{ fieldsToRetrieve, objectName, searchField, searchKey };
        if (ADDITIONAL_FILTERS.containsKey(extraFilterType)) {
            String extraFilter = getExtraFilter();
            result.add(extraFilter);
        } else {
            // If there is not extraFilter, replace {4} with an empty string
            result.add('');
        }
        return result;
    }

    private String getExtraFilter() {
        AdditionalFilter filter = (AdditionalFilter) ADDITIONAL_FILTERS.get(extraFilterType);
        return filter.getFilterConditions(filterFormattingParameters);
    }

    // INNER

    /**
     * Class names of implementations should follow the same convention so code could be replaced by this at anytime:
     * Type filterType = Type.forName('CustomLookupQueryConfiguration.' + this.extraFilterType);
     * AdditionalFilter filter = (AdditionalFilter) filterType.newInstance();
     * NOTE: In modern API versions, Type.forName can apparently only access public or global members,
     * regardless of test context or @TestVisible being present
     */

    private interface AdditionalFilter {
        String getFilterConditions(List<Object> formatParams);
    }

    private class AutomationTemplateFilter implements AdditionalFilter {
        private final String filterTemplate = 'AND RecordType.DeveloperName = \'\'Automation_Template\'\' AND Active__c = TRUE AND Id != \'\'{0}\'\'';

        // PUBLIC

        public String getFilterConditions(List<Object> formatParams) {
            return String.format(filterTemplate, formatParams);
        }
    }

    private class RegularGroupsFilter implements AdditionalFilter {
        private final String filterTemplate = 'AND Type = \'Regular\'';

        // PUBLIC

        public String getFilterConditions(List<Object> formatParams) {
            return String.format(filterTemplate, formatParams);
        }
    }

    private class TestScriptTitleFilter implements AdditionalFilter {
        private final String filterTemplate = 'OR Test_Title__c LIKE \'\'%{0}%\'\'';

        // PUBLIC

        public String getFilterConditions(List<Object> formatParams) {
            return String.format(filterTemplate, formatParams);
        }
    }

    private class ActiveUserFilter implements AdditionalFilter {
        private final String filterTemplate = 'AND IsActive = TRUE';

        // PUBLIC

        public String getFilterConditions(List<Object> formatParams) {
            return String.format(filterTemplate, formatParams);
        }
    }

    private class PreviousReleaseFilter implements AdditionalFilter {
        private final String filterTemplate = 'AND Status__c = \'Released\' AND Project__c = \'\'{0}\'\' AND Id != \'\'{1}\'\'';

        // PUBLIC

        public String getFilterConditions(List<Object> formatParams) {
            return String.format(filterTemplate, formatParams);
        }
    }

    private class CrtTestFilter implements AdditionalFilter {
        private final String filterTemplate = 'AND Test_Tool__c = \'Copado Robotic Testing\'';

        // PUBLIC

        public String getFilterConditions(List<Object> formatParams) {
            return String.format(filterTemplate, formatParams);
        }
    }
}