public with sharing class DatatableServiceCtrl extends DatatableColumnsConfiguration {
    
    // PUBLIC

    @AuraEnabled(cacheable=false)
    public static List<DatatableServiceColumnConfig> fetchColumnsConfiguration(DatatableColumnsConfiguration columnsConfiguration) {
        try {
            return columnsConfiguration.getColumnsConfig();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<SObject> fetchData(DatatableQueryConfiguration queryConfiguration) {
        try {
            List<SObject> data = Database.query(queryConfiguration.getFormattedQuery());
            return data;
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