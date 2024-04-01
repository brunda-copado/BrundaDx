public with sharing class ResultViewerCtrl {
    @AuraEnabled
    public static String fetchResultViewerComponent(String recordId) {
        if (recordId == null) {
            throw new AuraHandledException(String.format(Label.MissingRequiredParameters, new List<String>{ 'Result record Id' }));
        }
        try {
            String result;

            Result__c resultRec = new ResultsSelector().byId(recordId);
            if (resultRec != null) {
                result = String.isBlank(resultRec?.JobStep__r?.Result_Viewer_Component__c)
                    ? resultRec?.Function__r?.Result_Viewer_Component__c
                    : resultRec?.JobStep__r?.Result_Viewer_Component__c;
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(String.format(Label.ResultViewerComponentNotFound, new List<Object>{ e.getMessage() }));
        }
    }
}