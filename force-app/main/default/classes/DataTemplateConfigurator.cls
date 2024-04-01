@SuppressWarnings('PMD')
public with sharing class DataTemplateConfigurator {
    @TestVisible
    private static final String ADD_DESCRIBE_SOBJECT = 'ADD_Describe_SObject_Result';
    private static final String ADD_DESCRIBE_GLOBAL = 'ADD_Describe_Global_Result';

    private static final String DEFAULT_FILTER_LOGIC = '1';
    private static final String CONTINUE_UNTIL_BLOCKER = 'Continue deployment until blocker issue';
    private static final String DEFAULT_ATTACHMENT_OPTION = 'No Attachments';
    private static final Integer DEFAULT_BATCH_SIZE = 200;
    private static final Boolean DEAFULT_MATCH_RECORD_TYPE = false;
    private static final Boolean DEFAULT_MATCH_OWNER = false;
    private static final String DEFAULT_SELECTED_ATTACHMENT_TYPE = 'files';

    private static final Set<String> SCRAMBLE_FIELD_TYPES = new Set<String>{ 'textarea', 'text', 'currency', 'double', 'percent', 'string', 'int' };
    private static final Set<String> SCRAMBLE_WITH_FORMAT_FIELD_TYPES = new Set<String>{
        'textarea',
        'text',
        'currency',
        'double',
        'percent',
        'string',
        'int',
        'phone',
        'email'
    };

    private String recordId;
    private String orgId;
    private String mainObject;

    private Map<String, Attachment> existingAttachments {
        get {
            if (existingAttachments == null) {
                existingAttachments = new Map<String, Attachment>();
                for (
                    Attachment attachment : new AttachmentsSelector()
                        .byParentIdAndName(
                            new Set<Id>{ this.recordId, this.orgId },
                            new Set<String>{ ADD_DESCRIBE_GLOBAL, ADD_DESCRIBE_SOBJECT, DataTemplateDetail.ATTACHMENT_NAME }
                        )
                ) {
                    existingAttachments.put(attachment.Name, attachment);
                }
            }
            return existingAttachments;
        }
        set;
    }

    private List<String> disabledFields {
        get {
            if (disabledFields == null) {
                disabledFields = new List<String>();
                for (Data_Template_Setup__mdt templateSetup : [
                    SELECT Id, API_Names__c
                    FROM Data_Template_Setup__mdt
                    WHERE DeveloperName = 'Disabled_Fields'
                    LIMIT 1
                ]) {
                    if (String.isNotBlank(templateSetup.API_Names__c)) {
                        for (String name : templateSetup.API_Names__c.split(',')) {
                            disabledFields.add(name.toLowerCase().trim());
                        }
                    }
                }
            }
            return disabledFields;
        }
        set;
    }

    private List<String> disabledChildObjects {
        get {
            if (disabledChildObjects == null) {
                disabledChildObjects = new List<String>();
                for (Data_Template_Setup__mdt templateSetup : [
                    SELECT Id, API_Names__c
                    FROM Data_Template_Setup__mdt
                    WHERE DeveloperName = 'Disabled_Child_Objects'
                    LIMIT 1
                ]) {
                    if (String.isNotBlank(templateSetup.API_Names__c)) {
                        for (String name : templateSetup.API_Names__c.split(',')) {
                            disabledChildObjects.add(name.toLowerCase().trim());
                        }
                    }
                }
            }
            return disabledChildObjects;
        }
        set;
    }

    public DataTemplateConfigurator(String recordId) {
        this.recordId = recordId;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static boolean checkCredentialAccess(String credential) {
        List<Org__c> orgs = [SELECT UserRecordAccess.HasReadAccess FROM Org__c WHERE Id = :credential];
        return !orgs.isEmpty() ? orgs.get(0).UserRecordAccess.HasReadAccess : false;
    }

    public void setSource(String orgId, String mainObject) {
        this.orgId = orgId;
        this.mainObject = mainObject;

        List<Attachment> attachmentsToUpsert = new List<Attachment>();

        DescribeSObjectService.DescribeResponse fieldsResponse = fetchFields(this.orgId, this.mainObject);

        attachmentsToUpsert.add(updateObjectDescribeAttachment(this.recordId, fieldsResponse));
        attachmentsToUpsert.add(updateTemplateDetailAttachment(this.recordId, fieldsResponse, this.orgId, this.mainObject));

        Utilities.Secure_DML(attachmentsToUpsert, Utilities.DML_Action.UPS, Schema.SObjectType.Attachment);
    }

    public Attachment updateTemplateDetail(String templateDetail) {
        return updateTemplateDetail((DataTemplateDetail) JSON.deserialize(templateDetail, DataTemplateDetail.class));
    }

    public Attachment updateTemplateDetail(DataTemplateDetail templateDetail) {
        Attachment result = existingAttachments.containsKey(DataTemplateDetail.ATTACHMENT_NAME)
            ? existingAttachments.get(DataTemplateDetail.ATTACHMENT_NAME)
            : createAttachment(DataTemplateDetail.ATTACHMENT_NAME, recordId);
        
        if(!templateDetail.childrenObjectsReferenceList.isEmpty()){
            for(Integer i = (templateDetail.childrenObjectsReferenceList.size() - 1); i >= 0; i--){
                if(null == templateDetail.childrenObjectsReferenceList[i].templateId){
                    templateDetail.childrenObjectsReferenceList.remove(i);
                }
            }
        }
        if(!templateDetail.parentObjectsReferenceList.isEmpty()){
            for(Integer i = (templateDetail.parentObjectsReferenceList.size() - 1); i >= 0; i--){
                if(null == templateDetail.parentObjectsReferenceList[i].templateId){
                    templateDetail.parentObjectsReferenceList.remove(i);
                }
            }
        }
        result.Body = Blob.valueOf(JSON.serialize(templateDetail));
        Utilities.Secure_DML(result, Utilities.DML_Action.UPS, Schema.SObjectType.Attachment);
        return result;
    }

    public DataTemplateDetail getTemplateDetail() {
        if (!existingAttachments.containsKey(DataTemplateDetail.ATTACHMENT_NAME)) {
            throw new ApplicationException('Template Detail attachment not found');
        }
        Attachment attachment = existingAttachments.get(DataTemplateDetail.ATTACHMENT_NAME);
        DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(attachment.Body.toString(), DataTemplateDetail.class);
        return templateDetail;
    }

    public List<DescribeSObjectService.CopadoField> getObjectDescribeFields() {
        if (!existingAttachments.containsKey(ADD_DESCRIBE_SOBJECT)) {
            throw new ApplicationException('ADD_Describe_SObject_Result attachment not found');
        }
        Attachment attachment = existingAttachments.get(ADD_DESCRIBE_SOBJECT);
        DescribeSObjectService.DescribeResponse describeResponse = (DescribeSObjectService.DescribeResponse) JSON.deserialize(
            attachment.Body.toString(),
            DescribeSObjectService.DescribeResponse.class
        );
        return describeResponse.fields;
    }

    public void setFilters(List<DataFilter> filters, String filterLogic, Decimal batchSize, Decimal recordLimit) {
        DataTemplateDetail templateDetail = existingAttachments.containsKey(DataTemplateDetail.ATTACHMENT_NAME)
            ? (DataTemplateDetail) JSON.deserialize(
                  existingAttachments.get(DataTemplateDetail.ATTACHMENT_NAME).Body.toString(),
                  DataTemplateDetail.class
              )
            : new DataTemplateDetail();
        templateDetail = configureFilters(templateDetail, filters, filterLogic, batchSize, recordLimit);
        updateTemplateDetail(templateDetail);
    }

    private DescribeSObjectService.DescribeResponse fetchFields(String orgId, String mainObject) {
        DescribeSObjectService.DescribeResponse fieldsResponse = new DescribeSObjectService(orgId).getFields(mainObject);
        if (!fieldsResponse.success) {
            throw new ApplicationException(fieldsResponse.error);
        }
        return fieldsResponse;
    }

    private Attachment updateObjectDescribeAttachment(String recordId, DescribeSObjectService.DescribeResponse fieldsResponse) {
        Attachment result = existingAttachments.containsKey(ADD_DESCRIBE_SOBJECT)
            ? existingAttachments.get(ADD_DESCRIBE_SOBJECT)
            : createAttachment(ADD_DESCRIBE_SOBJECT, recordId);
        result.Body = Blob.valueOf(JSON.serialize(fieldsResponse));
        return result;
    }

    private Attachment updateTemplateDetailAttachment(
        String recordId,
        DescribeSObjectService.DescribeResponse fieldsResponse,
        String orgId,
        String mainObject
    ) {
        Boolean templateDetailAlreadyExists = existingAttachments.containsKey(DataTemplateDetail.ATTACHMENT_NAME);
        Attachment result = templateDetailAlreadyExists
            ? existingAttachments.get(DataTemplateDetail.ATTACHMENT_NAME)
            : createAttachment(DataTemplateDetail.ATTACHMENT_NAME, recordId);
        DataTemplateDetail templateDetail = templateDetailAlreadyExists
            ? (DataTemplateDetail) JSON.deserialize(
                  existingAttachments.get(DataTemplateDetail.ATTACHMENT_NAME).Body.toString(),
                  DataTemplateDetail.class
              )
            : new DataTemplateDetail();

        templateDetail = configureSourceValues(templateDetail, recordId, orgId, mainObject);
        templateDetail = templateDetailAlreadyExists ? templateDetail : configureDefaultValues(templateDetail);
        templateDetail = configureChildRelations(templateDetail, fieldsResponse);
        templateDetail = configureSelectedFields(templateDetail, fieldsResponse);

        result.Body = Blob.valueOf(JSON.serialize(templateDetail));
        return result;
    }

    private DataTemplateDetail configureFilters(
        DataTemplateDetail templateDetail,
        List<DataFilter> filters,
        String filterLogic,
        Decimal batchSize,
        Decimal recordLimit
    ) {
        templateDetail.queryFilterList = convertFilters(filters);
        templateDetail.dataTemplate.templateFilterLogic = filterLogic;
        templateDetail.dataTemplate.templateBatchSize = batchSize;
        templateDetail.dataTemplate.templateQueryLimit = recordLimit;
        return templateDetail;
    }

    private DataTemplateDetail configureSourceValues(DataTemplateDetail templateDetail, String recordId, String orgId, String mainObject) {
        templateDetail.dataTemplate.templateId = recordId;
        templateDetail.dataTemplate.templateSourceOrg = orgId;
        templateDetail.dataTemplate.templateMainObject = mainObject;
        return templateDetail;
    }

    // To-Do: change this to get the default values from the record (when possible)
    private DataTemplateDetail configureDefaultValues(DataTemplateDetail templateDetail) {
        Data_Template__c template = [SELECT Name, Description__c FROM Data_Template__c WHERE Id = :this.recordId WITH SECURITY_ENFORCED LIMIT 1];
        templateDetail.dataTemplate.templateName = template.Name;
        templateDetail.dataTemplate.templateDescription = template.Description__c;
        templateDetail.dataTemplate.templateMatchRecordTypes = DEAFULT_MATCH_RECORD_TYPE;
        templateDetail.dataTemplate.templateMatchOwners = DEFAULT_MATCH_OWNER;
        templateDetail.dataTemplate.templateFilterLogic = DEFAULT_FILTER_LOGIC;
        templateDetail.dataTemplate.templateContinueOnError = CONTINUE_UNTIL_BLOCKER;
        templateDetail.dataTemplate.templateBatchSize = DEFAULT_BATCH_SIZE;
        templateDetail.dataTemplate.templateAttachmentOption = DEFAULT_ATTACHMENT_OPTION;
        templateDetail.dataTemplate.templateSelectedAttachmentType = DEFAULT_SELECTED_ATTACHMENT_TYPE;
        return templateDetail;
    }

    private DataTemplateDetail configureChildRelations(DataTemplateDetail templateDetail, DescribeSObjectService.DescribeResponse fieldsResponse) {
        Map<String, String> objectLabelsByObjectName = getObjectLabels();
        Set<String> beforeRefreshChilds = !templateDetail.selectableChildRelationsMap?.keySet().isEmpty()
            ? new Set<String>(templateDetail.selectableChildRelationsMap?.keySet())
            : new Set<String>();
        Set<String> afterRefreshChilds = new Set<String>();

        if (fieldsResponse?.childRelationships != null) {
            for (DescribeSObjectService.CopadoChildRelationship childRelationShip : fieldsResponse.childRelationships) {
                String objectName = childRelationShip.childSObject;
                String childRelationshipName = childRelationShip.relationshipName;
                if (String.isBlank(childRelationshipName) || disabledChildObjects.contains(childRelationshipName.toLowerCase())) {
                    continue;
                }

                DataTemplateDetail.CopadoSelectedChildRelationship child = new DataTemplateDetail.CopadoSelectedChildRelationship();
                child.childSObject = objectName;
                child.field = childRelationShip.field;
                child.relationshipName = childRelationshipName;
                child.deploymentTemplateNameMap = new Map<String, String>();
                child.objectApiNameMap = new Map<String, String>{
                    childRelationShip.childSObject => objectLabelsByObjectName.containsKey(objectName) &&
                        String.isNotBlank(objectLabelsByObjectName.get(objectName))
                        ? objectLabelsByObjectName.get(objectName)
                        : objectName
                };

                String key = childRelationShip?.field + '-' + childRelationshipName;
                //check if child is already selected.
                Boolean childAlreadyInSelectableMap = templateDetail.selectableChildRelationsMap.containsKey(key);

                // if child is already selected keep selected child, deployment templatename during refresh,
                if (childAlreadyInSelectableMap) {
                    child.isSelected = templateDetail.selectableChildRelationsMap.get(key).isSelected;
                    child.deploymentTemplate = templateDetail.selectableChildRelationsMap.get(key).deploymentTemplate;
                    child.deploymentTemplateNameMap = templateDetail.selectableChildRelationsMap.get(key).deploymentTemplateNameMap;
                }
                afterRefreshChilds.add(key);
                templateDetail.selectableChildRelationsMap.put(key, child);
            }
        }

        if (!beforeRefreshChilds.isEmpty()) {
            beforeRefreshChilds.removeAll(afterRefreshChilds);
        }

        if (!beforeRefreshChilds.isEmpty() && !templateDetail.selectableChildRelationsMap?.isEmpty()) {
            for (String childObject : beforeRefreshChilds) {
                if (templateDetail.selectableChildRelationsMap.containsKey(childObject)) {
                    templateDetail.selectableChildRelationsMap.remove(childObject);
                }
            }
        }

        return templateDetail;
    }

    private DataTemplateDetail configureSelectedFields(DataTemplateDetail templateDetail, DescribeSObjectService.DescribeResponse fieldsResponse) {
        Map<String, String> objectLabelsByObjectName = getObjectLabels();
        Boolean newlyCreatedTemplate = templateDetail.selectableFieldsMap.isEmpty();
        Set<String> fieldsAdded = new Set<String>();
        Set<String> externalIdFields = new Set<String>();
        Set<String> newlyAddedExternalIdFields = new Set<String>();
        String previouslySetExternalIdField;

        if (fieldsResponse?.fields != null) {
            for (DescribeSObjectService.CopadoField field : fieldsResponse.fields) {
                if (!field.isId() && fieldIsNotAllowed(field)) {
                    continue;
                }

                String fieldName = field.Name;

                Boolean fieldAlreadyInSelectableMap = templateDetail.selectableFieldsMap.containsKey(fieldName);

                DataTemplateDetail.CopadoSelectedField selectedField = new DataTemplateDetail.CopadoSelectedField();
                selectedField.label = field.label;
                selectedField.name = fieldName;
                selectedField.fieldType = field.type;
                selectedField.externalId = field.externalId;

                if (field.externalId) {
                    externalIdFields.add(fieldName);
                    if (fieldAlreadyInSelectableMap && templateDetail.selectableFieldsMap.get(fieldName).useAsExternalId) {
                        previouslySetExternalIdField = fieldName;
                    } else if (!fieldAlreadyInSelectableMap) {
                        newlyAddedExternalIdFields.add(fieldName);
                    }
                }

                if (field.referenceTo != null) {
                    for (String refTo : field.referenceTo) {
                        // Note: fallback to API name
                        String objectLabel = objectLabelsByObjectName.containsKey(refTo) && String.isNotBlank(objectLabelsByObjectName.get(refTo))
                            ? objectLabelsByObjectName.get(refTo)
                            : refTo;
                        selectedField.parentObjectApiNameMap.put(refTo, objectLabel);
                    }
                }

                // keep selected fields
                if (fieldAlreadyInSelectableMap) {
                    selectedField.isSelected = templateDetail.selectableFieldsMap.get(fieldName).isSelected;
                } else {
                    selectedField.isSelected = (field.referenceTo == null);
                }

                // keep content update values
                if (fieldAlreadyInSelectableMap) {
                    selectedField.fieldContentUpdate = templateDetail.selectableFieldsMap.get(fieldName).fieldContentUpdate;
                }

                // keep replaceValues
                if (fieldAlreadyInSelectableMap) {
                    selectedField.replaceValue = templateDetail.selectableFieldsMap.get(fieldName).replaceValue;
                    selectedField.replaceValueNumber = templateDetail.selectableFieldsMap.get(fieldName).replaceValueNumber;
                    selectedField.replaceValueDate = templateDetail.selectableFieldsMap.get(fieldName).replaceValueDate;
                    selectedField.replaceValueDatetime = templateDetail.selectableFieldsMap.get(fieldName).replaceValueDatetime;
                }

                // keep deployment template values
                if (fieldAlreadyInSelectableMap) {
                    selectedField.deploymentTemplate = templateDetail.selectableFieldsMap.get(fieldName).deploymentTemplate;
                    selectedField.deploymentTemplateNameMap = templateDetail.selectableFieldsMap.get(fieldName).deploymentTemplateNameMap;
                }

                selectedField.contentValueUpdateValues = new Map<String, String>();
                if (field.externalId) {
                    selectedField.contentValueUpdateValues.put(Label.Copado_Record_Matching, 'recordMatching');
                } else {
                    selectedField.contentValueUpdateValues.put(Label.Replace_Value, 'replace');
                    if (SCRAMBLE_FIELD_TYPES.contains(field.type)) {
                        selectedField.contentValueUpdateValues.put(Label.Scramble_Value, 'scramble');
                    }
                    if (SCRAMBLE_WITH_FORMAT_FIELD_TYPES.contains(field.type)) {
                        selectedField.contentValueUpdateValues.put(Label.Scramble_With_Format, 'scrambleWithFormat');
                    }
                }

                templateDetail.selectableFieldsMap.put(fieldName, selectedField);
                fieldsAdded.add(fieldName);
            }
        }

        if (String.isNotBlank(previouslySetExternalIdField) && templateDetail.selectableFieldsMap.containsKey(previouslySetExternalIdField)) {
            templateDetail.selectableFieldsMap.get(previouslySetExternalIdField).useAsExternalId = true;
        } else if (externalIdFields.size() == 1 && newlyAddedExternalIdFields.size() > 0) {
            for (String field : externalIdFields) {
                if (templateDetail.selectableFieldsMap.containsKey(field)) {
                    templateDetail.selectableFieldsMap.get(field).useAsExternalId = true;
                    break;
                }
            }
        }

        Set<String> fieldsToRemove = new Set<String>(templateDetail.selectableFieldsMap.keySet());
        fieldsToRemove.removeAll(fieldsAdded);
        for (String fieldName : fieldsToRemove) {
            templateDetail.selectableFieldsMap.remove(fieldName);
        }

        return templateDetail;
    }

    private Map<String, String> getObjectLabels() {
        Map<String, String> result = new Map<String, String>();
        if (existingAttachments.containsKey(ADD_DESCRIBE_GLOBAL)) {
            DescribeSObjectService.DescribeGlobalResponse objectsResponse = (DescribeSObjectService.DescribeGlobalResponse) JSON.deserialize(
                existingAttachments.get(ADD_DESCRIBE_GLOBAL).Body.toString(),
                DescribeSObjectService.DescribeGlobalResponse.class
            );
            if (objectsResponse?.sobjects != null) {
                for (DescribeSObjectService.CopadoObject copadoObject : objectsResponse.sobjects) {
                    result.put(copadoObject.name, copadoObject.label);
                }
            }
        }
        return result;
    }

    private Boolean fieldIsNotAllowed(DescribeSObjectService.CopadoField field) {
        String name = field.name.toLowerCase();
        return ((field.creatable != null && !field.creatable) && (field.updateable != null && !field.updateable)) ||
            disabledFields.contains(name) ||
            field.isCompound() ||
            name == 'ownerid';
    }

    private Attachment createAttachment(String name, String parentId) {
        Attachment result = new Attachment();
        result.ParentId = parentId;
        result.Name = name;
        return result;
    }

    private List<QueryEditor.CriteriaWrapper> convertFilters(List<DataFilter> filters) {
        // convert DataFilter to CriteriaWrapper (compatibility)
        List<QueryEditor.CriteriaWrapper> result = new List<QueryEditor.CriteriaWrapper>();
        for (DataFilter filter : filters) {
            result.add(filter.toQueryCriteria());
        }
        return result;
    }
}