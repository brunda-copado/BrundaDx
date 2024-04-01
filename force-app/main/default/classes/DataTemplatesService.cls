public with sharing class DataTemplatesService {
    private Set<Id> dataTemplateIds;

    private final Map<Id, Data_Template__c> dataTemplatesById {
        get {
            if (dataTemplatesById == null) {
                dataTemplatesById = new Map<Id, Data_Template__c>(new DataTemplatesSelector().byId(this.dataTemplateIds));
            }
            return dataTemplatesById;
        }
        set;
    }

    private final Map<Id, Set<Id>> relatedDataTemplateIdsByDataTemplate {
        get {
            if (relatedDataTemplateIdsByDataTemplate == null) {
                relatedDataTemplateIdsByDataTemplate = hierarchyDataTemplateIdsByMainDataTemplate(
                    relatedDataTemplateIdsByDataTemplate(this.dataTemplateIds)
                );
            }
            return relatedDataTemplateIdsByDataTemplate;
        }
        set;
    }

    private final Map<Id, DataTemplateDetail> dataTemplateDetailsById {
        get {
            if (dataTemplateDetailsById == null) {
                dataTemplateDetailsById = dataTemplateDetails(this.dataTemplateIds);
            }
            return dataTemplateDetailsById;
        }
        set;
    }

    private final Map<Id, DataFiltersConfiguration> filterConfigurationById {
        get {
            if (filterConfigurationById == null) {
                filterConfigurationById = filtersConfiguration(this.dataTemplateIds);
            }
            return filterConfigurationById;
        }
        set;
    }

    public DataTemplatesService(Set<Id> dataTemplateIds) {
        this.dataTemplateIds = dataTemplateIds;
    }

    public Data_Template__c getDataTemplate(Id dataTemplateId) {
        return this.dataTemplatesById.get(dataTemplateId);
    }

    public Set<Id> getRelatedDataTemplates(Id dataTemplateId) {
        return this.relatedDataTemplateIdsByDataTemplate.containsKey(dataTemplateId)
            ? this.relatedDataTemplateIdsByDataTemplate.get(dataTemplateId)
            : new Set<Id>();
    }

    public Map<Id, Set<Id>> getRelatedDataTemplates(Set<Id> dataTemplateIds) {
        return this.relatedDataTemplateIdsByDataTemplate;
    }

    public DataFiltersConfiguration getFiltersConfiguration(Id dataTemplateId) {
        return this.filterConfigurationById.get(dataTemplateId);
    }

    /** warning: recursive method with recursive queries, as we need to parse the attachment body to get IDs there is no workaround */
    private Map<Id, Set<Id>> relatedDataTemplateIdsByDataTemplate(Set<Id> dataTemplateIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        for (Id dataTemplateId : dataTemplateIds) {
            if (!result.containsKey(dataTemplateId)) {
                result.put(dataTemplateId, new Set<Id>());
            }
        }

        if (!dataTemplateIds.isEmpty()) {
            Map<Id, DataTemplateDetail> dataTemplateDetailsById = dataTemplateDetails(dataTemplateIds);
            for (Id dataTemplateId : dataTemplateIds) {
                if (dataTemplateDetailsById.containsKey(dataTemplateId)) {
                    DataTemplateDetail templateDetail = dataTemplateDetailsById.get(dataTemplateId);

                    if (!result.containsKey(dataTemplateId)) {
                        result.put(dataTemplateId, new Set<Id>());
                    }

                    Set<Id> parentDataTemplateIds = getRelationTemplateDetailsIds(templateDetail.parentObjectsReferenceList);
                    result.get(dataTemplateId).addAll(parentDataTemplateIds);
                    Set<Id> childDataTemplateIds = getRelationTemplateDetailsIds(templateDetail.childrenObjectsReferenceList);
                    result.get(dataTemplateId).addAll(childDataTemplateIds);

                    Set<Id> allRelatedDataTemplateIds = new Set<Id>(parentDataTemplateIds);
                    allRelatedDataTemplateIds.addAll(childDataTemplateIds);
                    result.putAll(relatedDataTemplateIdsByDataTemplate(allRelatedDataTemplateIds));
                }
            }
        }

        return result;
    }

    private Map<Id, Set<Id>> hierarchyDataTemplateIdsByMainDataTemplate(Map<Id, Set<Id>> relatedDataTemplateIdsByDataTemplate) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        for (Id dataTemplateId : relatedDataTemplateIdsByDataTemplate.keySet()) {
            if (!result.containsKey(dataTemplateId)) {
                result.put(dataTemplateId, new Set<Id>());
            }
            Set<Id> relatedDataTemplates = relatedDataTemplateIdsByDataTemplate.get(dataTemplateId);
            result.get(dataTemplateId).addAll(relatedDataTemplates);
            for (Id relatedDataTemplate : relatedDataTemplates) {
                if (relatedDataTemplateIdsByDataTemplate.containsKey(relatedDataTemplate)) {
                    result.get(dataTemplateId).addAll(relatedDataTemplateIdsByDataTemplate.get(relatedDataTemplate));
                }
            }
        }

        return result;
    }

    private Set<Id> getRelationTemplateDetailsIds(List<DataTemplateDetail.RelationTemplateDetails> relationTemplateDetails) {
        Set<Id> result = new Set<Id>();
        for (DataTemplateDetail.RelationTemplateDetails relationTemplateDetail : relationTemplateDetails) {
            String dataTemplateId = relationTemplateDetail.templateId;
            if (String.isNotBlank(dataTemplateId) && dataTemplateId instanceof Id) {
                result.add(dataTemplateId);
            }
        }
        return result;
    }

    private Map<Id, DataTemplateDetail> dataTemplateDetails(Set<Id> dataTemplateIds) {
        Map<Id, DataTemplateDetail> result = new Map<Id, DataTemplateDetail>();
        for (
            Attachment attachment : new AttachmentsSelector()
                .byParentIdAndName(dataTemplateIds, new Set<String>{ DataTemplateDetail.ATTACHMENT_NAME })
        ) {
            DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(attachment.Body.toString(), DataTemplateDetail.class);
            Id dataTemplateId = attachment.ParentId;
            result.put(dataTemplateId, templateDetail);
        }

        return result;
    }

    private Map<Id, DataFiltersConfiguration> filtersConfiguration(Set<Id> dataTemplateIds) {
        Map<Id, DataFiltersConfiguration> result = new Map<Id, DataFiltersConfiguration>();
        for (Id dataTemplateId : dataTemplateIds) {
            if (this.dataTemplateDetailsById.containsKey(dataTemplateId)) {
                DataTemplateDetail templateDetail = this.dataTemplateDetailsById.get(dataTemplateId);
                List<QueryEditor.CriteriaWrapper> queryFilters = templateDetail.queryFilterList;
                String templateLogic = templateDetail.dataTemplate.templateFilterLogic;

                DataFiltersConfiguration configuration = new DataFiltersConfiguration();
                configuration.filters = convertQueryFilters(queryFilters);
                configuration.filterLogic = templateLogic;

                result.put(dataTemplateId, configuration);
            }
        }
        return result;
    }

    private List<DataFilter> convertQueryFilters(List<QueryEditor.CriteriaWrapper> queryFilters) {
        List<DataFilter> result = new List<DataFilter>();
        for (QueryEditor.CriteriaWrapper queryFilter : queryFilters) {
            if(String.isNotBlank(queryFilter.getFinalValue())){
                result.add(new DataFilter(queryFilter));
            }
        }
        return result;
    }
}