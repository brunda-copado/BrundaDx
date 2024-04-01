public with sharing class DataSetValidator {
    private DataSetsService service;

    public DataSetValidator(Set<Id> dataSetIds) {
        this.service = new DataSetsService(dataSetIds);
    }

    public Boolean hasValidFiles(Id dataSetId) {
        Boolean result = false;

        Data_Set__c dataSet = this.service.getDataSet(dataSetId);
        if (dataSet != null) {
            List<String> expectedFileNames = getExpectedFileNames(dataSet);
            List<String> dataSetFileNames = getCurrentFileNames(dataSet);

            Map<String, Boolean> foundFileByName = new Map<String, Boolean>();

            for (String expectedFileName : expectedFileNames) {
                Boolean found = dataSetFileNames.contains(expectedFileName);
                foundFileByName.put(expectedFileName, found);
            }

            result = allTrue(foundFileByName.values());
        }

        return result;
    }

    private List<String> getExpectedFileNames(Data_Set__c dataSet) {
        List<String> result = new List<String>();

        List<Data_Template__c> dataTemplates = this.service.getDataTemplates(dataSet.Id);
        for (Data_Template__c dataTemplate : dataTemplates) {
            result.addAll(getExpectedFileNames(dataSet, dataTemplate));
        }

        return result;
    }

    private List<String> getExpectedFileNames(Data_Set__c dataSet, Data_Template__c dataTemplate) {
        List<String> result = new List<String>();

        String baseFileName = dataTemplate.Id + '-' + dataTemplate.Name;
        String csvExpectedFileName = baseFileName + '.records' + '.csv';
        String templateExpectedFileName = (dataSet.Data_Template__c == dataTemplate.Id ? 'MT-' : '') + baseFileName + '.template';

        result.add(csvExpectedFileName);
        result.add(templateExpectedFileName);

        return result;
    }

    private List<String> getCurrentFileNames(Data_Set__c dataSet) {
        List<String> result = new List<String>();

        List<ContentDocument> contentDocuments = this.service.getContentDocuments(dataSet.Id);
        for (ContentDocument contentDocument : contentDocuments) {
            String documentFileName = contentDocument.Title;
            result.add(documentFileName);
        }

        return result;
    }

    private Boolean allTrue(List<Boolean> conditions) {
        Set<Boolean> conditionsSet = new Set<Boolean>(conditions);
        return !conditionsSet.contains(false);
    }
}