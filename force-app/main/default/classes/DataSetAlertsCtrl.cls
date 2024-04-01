public with sharing class DataSetAlertsCtrl {
    @AuraEnabled(cacheable=true)
    public static List<CopadoAlert> verifyDataSet(Id recordId) {
        try {
            List<CopadoAlert> result = new List<CopadoAlert>();

            List<Data_Set__c> dataSets = new DataSetsSelector().byId(new Set<Id>{ recordId });
            if (!dataSets.isEmpty()) {
                Data_Set__c dataSet = dataSets.get(0);

                result.addAll(validateDataTemplateFilters(dataSet));
            }

            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static List<CopadoAlert> validateDataTemplateFilters(Data_Set__c dataSet) {
        Id dataTemplateId = dataSet.Data_Template__c;
        return validateDataTemplateFilters(dataTemplateId);
    }

    private static List<CopadoAlert> validateDataTemplateFilters(Id dataTemplateId) {
        List<CopadoAlert> result = new List<CopadoAlert>();

        DataTemplatesService dataTemplatesService = new DataTemplatesService(new Set<Id>{ dataTemplateId });

        DataFiltersConfiguration filtersConfiguration = dataTemplatesService.getFiltersConfiguration(dataTemplateId);
        List<DataFilter> filters = filtersConfiguration?.filters != null ? filtersConfiguration.filters : new List<DataFilter>();

        if (!filters.isEmpty()) {
            Data_Template__c dataTemplate = dataTemplatesService.getDataTemplate(dataTemplateId);

            if (String.isNotBlank(dataTemplate.Template_Source_Org__c) && String.isNotBlank(dataTemplate.Main_Object__c)) {
                DescribeSObjectService.DescribeResponse describeResponse = new DescribeSObjectService(dataTemplate.Template_Source_Org__c)
                    .getFields(dataTemplate.Main_Object__c);

                for (DataFilter filter : filters) {
                    DescribeSObjectService.CopadoField field = describeResponse.getField(filter.fieldName);
                    if (field != null && filter.fieldType != field.type) {
                        result.add(new CopadoAlert().message(Label.DataTemplateInvalidFilters).variant(CopadoAlert.Variant.WARNING));
                        break;
                    }
                }
            }
        }

        return result;
    }
}