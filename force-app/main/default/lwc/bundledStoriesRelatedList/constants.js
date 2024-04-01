import USER_STORY from '@salesforce/schema/User_Story__c';
import USER_STORY_RECORD_TYPE_FIELD from '@salesforce/schema/User_Story__c.RecordType.Name';
import ID_FIELD from '@salesforce/schema/User_Story__c.Id';
import NAME_FIELD from '@salesforce/schema/User_Story__c.Name';

import BUNDLED_STORIES_RELATED_LIST_TITLE from '@salesforce/label/c.Bundled_Stories';
import USER_STORY_BUNDLES_RELATED_LIST_TITLE from '@salesforce/label/c.User_Story_Bundle';
import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import NO_COLUMN_CONFIG_ERROR from '@salesforce/label/c.SprintWall_NoColumnError';
import ITEMS from '@salesforce/label/c.Items';

const ORDER_BY = 'Name ASC, Id ASC NULLS LAST, CreatedDate';
const ICON_NAME = 'standard:bundle_config';
const NUMBER_OF_RECORDS_LIMIT = 100;
const HIDE_DEFAULT_COLUMNS_ACTION = true;
const SORTABLE = true;
const ENABLE_INLINE_EDITING = false;
const SEARCHABLE = true;
const FILTERABLE = false;
const DEFAULT_SORT_FIELD = NAME_FIELD.fieldApiName;
const DEFAULT_SORT_DIRECTION = 'asc';
const KEY_FIELD = 'Id';

export const label = {
    ITEMS,
    FETCH_DATA_ERROR,
    BUNDLED_STORIES_RELATED_LIST_TITLE,
    USER_STORY_BUNDLES_RELATED_LIST_TITLE,
    NO_COLUMN_CONFIG_ERROR
};

export const schema = {
    USER_STORY,
    USER_STORY_RECORD_TYPE_FIELD,
    ID_FIELD: ID_FIELD
};

export const constants = {
    FETCH_DATA_ERROR,
    HIDE_DEFAULT_COLUMNS_ACTION,
    SORTABLE,
    ENABLE_INLINE_EDITING,
    SEARCHABLE,
    FILTERABLE,
    ORDER_BY,
    NUMBER_OF_RECORDS_LIMIT,
    DEFAULT_SORT_FIELD,
    DEFAULT_SORT_DIRECTION,
    KEY_FIELD,
    ICON_NAME
};