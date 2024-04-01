public with sharing class DataTemplateObjectFiltersCtrl {
    @AuraEnabled(cacheable=false)
    public static DataFiltersConfiguration getDataTemplateFilters(String recordId) {
        try {
            DataTemplatesService service = new DataTemplatesService(new Set<Id>{ recordId });
            return service.getFiltersConfiguration(recordId);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void updateDataTemplateFilters(
        String recordId,
        List<DataFilter> filters,
        String filterLogic,
        Decimal batchSize,
        Decimal recordLimit
    ) {
        try {
            new DataTemplateConfigurator(recordId).setFilters(filters, filterLogic, batchSize, recordLimit);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}