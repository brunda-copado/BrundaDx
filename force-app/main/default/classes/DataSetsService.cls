public with sharing class DataSetsService {
    private Set<Id> dataSetIds;

    private final Map<Id, Data_Set__c> dataSetsById {
        get {
            if (dataSetsById == null) {
                dataSetsById = new Map<Id, Data_Set__c>(new DataSetsSelector().byId(this.dataSetIds));
            }
            return dataSetsById;
        }
        set;
    }

    private final Map<Id, List<ContentDocument>> contentDocumentsByDataSetId {
        get {
            if (contentDocumentsByDataSetId == null) {
                contentDocumentsByDataSetId = contentDocumentsByDataSetId(this.dataSetIds);
            }
            return contentDocumentsByDataSetId;
        }
        set;
    }

    private final Map<Id, List<Data_Template__c>> dataTemplatesByDataSetId {
        get {
            if (dataTemplatesByDataSetId == null) {
                dataTemplatesByDataSetId = dataTemplatesByDataSetId(this.dataSetIds);
            }
            return dataTemplatesByDataSetId;
        }
        set;
    }

    public DataSetsService(Set<Id> dataSetIds) {
        this.dataSetIds = dataSetIds;
    }

    public Data_Set__c getDataSet(Id dataSetId) {
        return this.dataSetsById.containsKey(dataSetId) ? this.dataSetsById.get(dataSetId) : null;
    }

    public List<ContentDocument> getContentDocuments(Id dataSetId) {
        return this.contentDocumentsByDataSetId.containsKey(dataSetId)
            ? this.contentDocumentsByDataSetId.get(dataSetId)
            : new List<ContentDocument>();
    }

    public List<Data_Template__c> getDataTemplates(Id dataSetId) {
        return this.dataTemplatesByDataSetId.containsKey(dataSetId) ? this.dataTemplatesByDataSetId.get(dataSetId) : new List<Data_Template__c>();
    }

    private Map<Id, List<ContentDocument>> contentDocumentsByDataSetId(Set<Id> dataSetIds) {
        Map<Id, List<ContentDocument>> result = new Map<Id, List<ContentDocument>>();
        Map<Id, List<ContentDocumentLink>> contentDocumentLinksByDataSetId = SalesforceFilesService.contentDocumentLinksOfRecord(dataSetIds);
        for (Id dataSetId : contentDocumentLinksByDataSetId.keySet()) {
            result.put(dataSetId, new List<ContentDocument>());
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinksByDataSetId.get(dataSetId)) {
                result.get(dataSetId).add(contentDocumentLink.ContentDocument);
            }
        }
        return result;
    }

    private Map<Id, List<Data_Template__c>> dataTemplatesByDataSetId(Set<Id> dataSetIds) {
        Map<Id, List<Data_Template__c>> result = new Map<Id, List<Data_Template__c>>();

        Set<Id> dataTemplateIds = new Set<Id>();
        for (Id dataSetId : this.dataSetIds) {
            Data_Set__c dataSet = getDataSet(dataSetId);
            if (dataSet != null) {
                Id dataTemplateId = dataSet.Data_Template__c;
                dataTemplateIds.add(dataTemplateId);
            }
        }

        DataTemplatesService dataTemplatesService = new DataTemplatesService(dataTemplateIds);
        Map<Id, Set<Id>> dataTemplatesByMainDataTemplate = dataTemplatesService.getRelatedDataTemplates(dataTemplateIds);
        Set<Id> allDataTemplateIds = getAllIds(dataTemplatesByMainDataTemplate);
        Map<Id, Data_Template__c> dataTemplatesById = new Map<Id, Data_Template__c>(new DataTemplatesSelector().byId(allDataTemplateIds));

        for (Id dataSetId : this.dataSetIds) {
            Data_Set__c dataSet = getDataSet(dataSetId);
            Id dataTemplateId = dataSet.Data_Template__c;
            if (!result.containsKey(dataSetId)) {
                result.put(dataSetId, new List<Data_Template__c>());
            }
            if (dataTemplatesById.containsKey(dataTemplateId)) {
                result.get(dataSetId).add(dataTemplatesById.get(dataTemplateId));
            }
            if (dataTemplatesByMainDataTemplate.containsKey(dataTemplateId)) {
                Set<Id> relatedDataTemplates = dataTemplatesByMainDataTemplate.get(dataTemplateId);
                for (Id relatedDataTemplate : relatedDataTemplates) {
                    if (dataTemplatesById.containsKey(relatedDataTemplate)) {
                        result.get(dataSetId).add(dataTemplatesById.get(relatedDataTemplate));
                    }
                }
            }
        }
        return result;
    }

    private Set<Id> getAllIds(Map<Id, Set<Id>> collectionsByKey) {
        Set<Id> result = new Set<Id>();

        for (Id key : collectionsByKey.keySet()) {
            result.add(key);
            result.addAll(collectionsByKey.get(key));
        }

        return result;
    }
}