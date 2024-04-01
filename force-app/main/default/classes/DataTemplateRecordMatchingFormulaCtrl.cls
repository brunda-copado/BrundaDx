public with sharing class DataTemplateRecordMatchingFormulaCtrl {
    @AuraEnabled
    public static String getObjectFields(String orgId, String mainObject) {
        try {                  
            String result;
            DescribeSObjectService.DescribeResponse response = new DescribeSObjectService(orgId).getFields(mainObject);
            if (response.success && !response.fields.isEmpty()) {
                List<DescribeSObjectService.CopadoField> validFields = new List<DescribeSObjectService.CopadoField>();
                for (DescribeSObjectService.CopadoField field : response.fields) {
                    if (!validField(field)) {
                        continue;
                    }
                    validFields.add(field);
                }
                response.fields = validFields;
                response.fields.sort();
                result = JSON.serialize(response);
            }
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static boolean checkCredentialAccess(String credential) {
        try {
            return DataTemplateConfigurator.checkCredentialAccess(credential);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static Data_Template__c getDataTemplate(String templateId) {
        try {
            List<Data_Template__c> dataTemplate = new DataTemplatesSelector().byId(new Set<Id>{ templateId });
            return dataTemplate.get(0);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static Record_Matching_Formula__c getRecordMatchingFormula(String mainObject) {
        try {
            Record_Matching_Formula__c formula;
            List<Record_Matching_Formula__c> recordMatchingFormula = [
                SELECT Id, Name, Configuration_Source_Org__c, Object__c, Hash_Formula__c, Field_1__c, Field_2__c, Field_3__c, Field_Labels__c
                FROM Record_Matching_Formula__c
                WHERE Object__c = :mainObject
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!recordMatchingFormula.isEmpty()) {
                formula = recordMatchingFormula.get(0);
            }
            return formula;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Boolean validField(DescribeSObjectService.CopadoField field) {
        return field.filterable != null && field.filterable && !field.isCompound();
    }
}