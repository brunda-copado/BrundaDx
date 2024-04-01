import DATATABLE_TITLE from '@salesforce/label/c.Changes_to_merge';
import RELATED_LIST_ERROR from '@salesforce/label/c.Related_List_Error';
import FETCH_COLUMN_CONFIG_ERROR from '@salesforce/label/c.Fetch_Columns_Config_Error';
import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import NO_COLUMN_CONFIG_ERROR from '@salesforce/label/c.SprintWall_NoColumnError';
import REVIEW_CONFLICTS from '@salesforce/label/c.Review_Conflicts';

import ITEMS from '@salesforce/label/c.Items';
import Remove_Selection_Button from '@salesforce/label/c.Remove_Selection_Button';

import VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';
import CONTENT_SIZE_FIELD from '@salesforce/schema/ContentVersion.ContentSize';
import TITLE_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.Title';
import LATEST_PUBLISHED_VERSION_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.LatestPublishedVersionId';

import USER_STORY_METADATA from '@salesforce/schema/User_Story_Metadata__c';
import USER_STORY_METADATA_TYPE_FIELD from '@salesforce/schema/User_Story_Metadata__c.Type__c';
import USER_STORY_METADATA_ACTION_FIELD from '@salesforce/schema/User_Story_Metadata__c.Action__c';
import USER_STORY_METADATA_API_NAME_FIELD from '@salesforce/schema/User_Story_Metadata__c.Metadata_API_Name__c';
import USER_STORY_METADATA_MODULE_DIRECTORY_FIELD from '@salesforce/schema/User_Story_Metadata__c.ModuleDirectory__c';
import USER_STORY_METADATA_USER_STORY_FIELD from '@salesforce/schema/User_Story_Metadata__c.User_Story__c';
import USER_STORY_NAME_FIELD from '@salesforce/schema/User_Story__c.Name';

import copadoUtils from 'c/copadocoreUtils';

const NUMBER_OF_RECORDS_LIMIT = 25;
const ERROR_VARIANT = 'error';
const DEFAULT_SORT_FIELD = USER_STORY_METADATA_USER_STORY_FIELD.fieldApiName.replace('__c', '__r.LinkName');
const DEFAULT_SORT_DIRECTION = 'desc';
const KEY_FIELD = 'Id';

const FIELD_SET_NAME = 'MC_Promotion_User_Story_Metadata';
const RELATED_LIST_NAME = DATATABLE_TITLE;
const ORDER_BY = 'Name ASC, Id ASC NULLS LAST, CreatedDate';
const HIDE_DEFAULT_COLUMNS_ACTION = true;
const SORTABLE = true;
const ENABLE_INLINE_EDITING = false;
const SEARCHABLE = true;
const FILTERABLE = false;
const WARNING_VARIANT = 'warning';
const IGNORED_CHANGES_FILE_NAME = 'Ignored changes';

export const label = {
    ITEMS,
    Remove_Selection_Button,
    REVIEW_CONFLICTS
};

export const schema = {
    USER_STORY_METADATA: USER_STORY_METADATA.objectApiName,
    FIELD_SET_NAME,

    TITLE_FIELD,
    VERSION_DATA_FIELD,
    CONTENT_SIZE_FIELD,
    LATEST_PUBLISHED_VERSION_FIELD,
    RESULT_DOC_RELATIONSHIP: 'ContentDocumentLinks',

    USER_STORY_METADATA_TYPE_FIELD,
    USER_STORY_METADATA_ACTION_FIELD,
    USER_STORY_METADATA_API_NAME_FIELD,
    USER_STORY_METADATA_MODULE_DIRECTORY_FIELD,
    USER_STORY_METADATA_USER_STORY_FIELD,
    USER_STORY_NAME_FIELD,

    NAMESPACE: copadoUtils.namespace
};

export const constants = {
    RELATED_LIST_ERROR,
    FETCH_COLUMN_CONFIG_ERROR,
    FETCH_DATA_ERROR,
    HIDE_DEFAULT_COLUMNS_ACTION,
    SORTABLE,
    ENABLE_INLINE_EDITING,
    SEARCHABLE,
    FILTERABLE,
    ORDER_BY,
    NUMBER_OF_RECORDS_LIMIT,
    RELATED_LIST_NAME,
    ERROR_VARIANT,
    NO_COLUMN_CONFIG_ERROR,
    WARNING_VARIANT,

    IGNORED_CHANGES_FILE_NAME,
    MAX_FILE_SIZE_SUPPORTED: '5242880', // 5 MB = 5,242,880 Bytes (Binary)

    DEFAULT_SORT_FIELD,
    DEFAULT_SORT_DIRECTION,
    KEY_FIELD
};