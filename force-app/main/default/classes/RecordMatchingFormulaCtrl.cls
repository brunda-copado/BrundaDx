public with sharing class RecordMatchingFormulaCtrl {
    
    @AuraEnabled
    public static Boolean checkObjectAlreadyInUse(String objectName){
        try {
            return !new RecordMatchingFormulaSelector()
                            .byObjectName(objectName)
                            .isEmpty();

        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static Record_Matching_Formula__c getRecordMatchingFormula(String recordId){
        try {
            return new RecordMatchingFormulaSelector()
                            .byId(new Set<Id>{recordId})
                            .get(0);

        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}