import SF_ATTRIBUTE from '@salesforce/label/c.SF_Att';
import FIELD_LABEL from '@salesforce/label/c.Field_Label';
import API_NAME from '@salesforce/label/c.API_Name';
import FIELD_API_NAME from '@salesforce/label/c.Field_API_Name';
import DATA_TYPE from '@salesforce/label/c.Data_Type';
import USE_AS_EXTERNAL_ID from '@salesforce/label/c.Use_as_External_ID';
import FIELD_CONTENT_UPDATE from '@salesforce/label/c.Field_Content_Update';
import DEPLOYMENT_TEMPLATE from '@salesforce/label/c.Deployment_Template';
import OBJECT_FIELDS from '@salesforce/label/c.Object_Fields';
import PARENT_OBJECTS from '@salesforce/label/c.Parent_Objects';
import CHILD_OBJECTS from '@salesforce/label/c.Child_Objects';
import OBJECT_LABEL from '@salesforce/label/c.Object_Label';
import OBJECT_API_NAME from '@salesforce/label/c.Object_API_Name';
import RELATIONSHIP_NAME from '@salesforce/label/c.Relationship_Name';
import FIELDS from '@salesforce/label/c.FIELDS';
import OBJECT from '@salesforce/label/c.OBJECT';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import EDIT from '@salesforce/label/c.EDIT';
import REFRESH from '@salesforce/label/c.RefreshSchema';
import SEARCH_THIS_LIST from '@salesforce/label/c.Search_this_list';
import SELECT from '@salesforce/label/c.SELECT';
import EMPTY_SEARCH_MESSAGE from '@salesforce/label/c.EmptySearchMessage';
import NO_RELATED_OBJECT_MESSAGE from '@salesforce/label/c.RelatedObjectNotAvailableMessage';
import REQUIRED_FIELD_NOT_SELECTED from '@salesforce/label/c.RequiredFieldNotSelected';
import EXTERNAL_ID_WARNING_MESSAGE from '@salesforce/label/c.ExternalIdWarningMessage';
import SCHEMA_REFRESHED from '@salesforce/label/c.SchemaRefreshed';
import EDIT_DATA_TEMPLATE from '@salesforce/label/c.EditDataTemplate';
import DEACTIVATE from '@salesforce/label/c.Deactivate';
import EDIT_VALIDATION_MESSAGE from '@salesforce/label/c.DataTemplateEditValidationMsg';
import DATA_TEMPLATE_ACTIVE from '@salesforce/schema/Data_Template__c.Active__c';

export const label = {
    CANCEL,
    SAVE,
    EDIT,
    REFRESH,
    SEARCH_THIS_LIST,
    SF_ATTRIBUTE,
    FIELD_LABEL,
    FIELD_API_NAME,
    API_NAME,
    DATA_TYPE,
    USE_AS_EXTERNAL_ID,
    FIELD_CONTENT_UPDATE,
    EMPTY_SEARCH_MESSAGE,
    FIELDS,
    OBJECT,
    DEPLOYMENT_TEMPLATE,
    OBJECT_FIELDS,
    PARENT_OBJECTS,
    CHILD_OBJECTS,
    OBJECT_LABEL,
    OBJECT_API_NAME,
    RELATIONSHIP_NAME,
    NO_RELATED_OBJECT_MESSAGE,
    REQUIRED_FIELD_NOT_SELECTED,
    EXTERNAL_ID_WARNING_MESSAGE,
    EDIT_DATA_TEMPLATE,
    DEACTIVATE,
    EDIT_VALIDATION_MESSAGE,
    SCHEMA_REFRESHED
};

export const schema = { DATA_TEMPLATE_ACTIVE };

export const REPLACE_PROPERTIES = ['replaceValue', 'replaceValueNumber', 'replaceValueDate', 'replaceValueDatetime'];

export const SELECT_COLUMN = {
    label: '',
    hideDefaultActions: true,
    type: 'selectColumn',
    typeAttributes: {
        isSelected: { fieldName: 'isSelected' },
        readOnlyMode: { fieldName: 'readOnlyMode' },
        fieldName: { fieldName: 'name' }
    },
    initialWidth: 50
};

export const ATTRIBUTE_COLUMN = {
    label: SF_ATTRIBUTE,
    type: 'attribute',
    // not used, only for sorting
    fieldName: 'attribute',
    hideDefaultActions: true,
    sortable: true,
    typeAttributes: {
        isExternalId: { fieldName: 'externalId' },
        isRequired: { fieldName: 'required' }
    },
    initialWidth: 80
};

const FIELD_LABEL_COLUMN = {
    label: FIELD_LABEL,
    fieldName: 'label',
    hideDefaultActions: true,
    searchable: true,
    sortable: true,
    initialWidth: 200
};

const FIELD_API_NAME_COLUMN = {
    label: FIELD_API_NAME,
    fieldName: 'name',
    hideDefaultActions: true,
    searchable: true,
    sortable: true,
    initialWidth: 200
};

const OBJECT_LABEL_COLUMN = {
    label: OBJECT_LABEL,
    fieldName: 'objectLabel',
    hideDefaultActions: true,
    searchable: true,
    sortable: true,
    initialWidth: 200
};

const OBJECT_API_NAME_COLUMN = {
    label: OBJECT_API_NAME,
    type: 'objectName',
    fieldName: 'objectName',
    hideDefaultActions: true,
    searchable: true,
    sortable: true,
    initialWidth: 200
};

const RELATIONSHIP_NAME_COLUMN = {
    label: RELATIONSHIP_NAME,
    fieldName: 'relationshipName',
    hideDefaultActions: true,
    searchable: true,
    sortable: true,
    initialWidth: 200
};

const DATA_TYPE_COLUMN = { label: DATA_TYPE, fieldName: 'fieldType', hideDefaultActions: true, searchable: true, sortable: true, initialWidth: 100 };

export const USE_AS_EXTERNAL_ID_COLUMN = {
    label: USE_AS_EXTERNAL_ID,
    fieldName: 'useAsExternalId',
    type: 'selectExternalId',
    typeAttributes: {
        isSelected: { fieldName: 'isSelected' },
        isExternalId: { fieldName: 'externalId' },
        readOnlyMode: { fieldName: 'readOnlyMode' },
        fieldName: { fieldName: 'name' }
    },
    hideDefaultActions: true,
    searchable: true,
    sortable: true,
    initialWidth: 140
};

export const CONTENT_UPDATE_COLUMN = {
    label: FIELD_CONTENT_UPDATE,
    hideDefaultActions: true,
    searchable: true,
    type: 'contentUpdate',
    fieldName: 'fieldContentUpdate',
    typeAttributes: {
        contentValueUpdateValues: { fieldName: 'contentValueUpdateValues' },
        fieldContentUpdate: { fieldName: 'fieldContentUpdate' },
        replaceValue: { fieldName: 'replaceValue' },
        replaceValueNumber: { fieldName: 'replaceValueNumber' },
        replaceValueDate: { fieldName: 'replaceValueDate' },
        replaceValueDatetime: { fieldName: 'replaceValueDatetime' },
        isSelected: { fieldName: 'isSelected' },
        readOnlyMode: { fieldName: 'readOnlyMode' },
        fieldName: { fieldName: 'name' },
        fieldType: { fieldName: 'fieldType' },
        recordId: { fieldName: 'recordId' }
    },
    //initialWidth: 550,
    wrapText: true
};

const DEPLOYMENT_TEMPLATE_COLUMN = {
    label: label.DEPLOYMENT_TEMPLATE,
    hideDefaultActions: true,
    searchable: true,
    sortable: true,
    type: 'deploymentTemplate',
    fieldName: 'deploymentTemplate',
    typeAttributes: {
        recordId: { fieldName: 'recordId' },
        objectName: { fieldName: 'objectName' },
        objectLabel: { fieldName: 'objectLabel' },
        deploymentTemplateId: { fieldName: 'deploymentTemplateId' },
        isSelected: { fieldName: 'isSelected' },
        readOnlyMode: { fieldName: 'readOnlyMode' },
        fieldName: { fieldName: 'name' },
        fieldType: { fieldName: 'fieldType' }
    },
    //initialWidth: 450,
    wrapText: true
};

export const OBJECT_FIELDS_COLUMNS = [
    ATTRIBUTE_COLUMN,
    FIELD_LABEL_COLUMN,
    FIELD_API_NAME_COLUMN,
    DATA_TYPE_COLUMN,
    USE_AS_EXTERNAL_ID_COLUMN,
    CONTENT_UPDATE_COLUMN
];

export const PARENT_OBJECTS_COLUMNS = [
    ATTRIBUTE_COLUMN,
    FIELD_LABEL_COLUMN,
    FIELD_API_NAME_COLUMN,
    OBJECT_LABEL_COLUMN,
    OBJECT_API_NAME_COLUMN,
    DEPLOYMENT_TEMPLATE_COLUMN
];

export const CHILD_OBJECTS_COLUMNS = [OBJECT_LABEL_COLUMN, OBJECT_API_NAME_COLUMN, RELATIONSHIP_NAME_COLUMN, DEPLOYMENT_TEMPLATE_COLUMN];