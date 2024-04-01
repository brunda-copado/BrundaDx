public with sharing class DynamicDatatableCtrl {
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<ColumnConfig> fetchColumnsConfig(DynamicDatatableColumnsConfiguration columnsConfiguration) {
        try {
            return columnsConfiguration.getColumnsConfig();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<SObject> fetchData(DynamicDatatableQueryConfiguration queryConfig) {
        try {
            return Database.query(queryConfig.getFormattedQuery());
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void updateRecords(List<SObject> records) {
        try {
            // FALSE POSITIVE: OLS and FLS checks are already performed by the LWC where this method is being used
            update records;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}