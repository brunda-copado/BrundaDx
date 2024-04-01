import USER_STORY_METADATA from '@salesforce/schema/User_Story_Metadata__c';
import USER_STORY_FIELD from '@salesforce/schema/User_Story_Metadata__c.User_Story__c';

import DATATABLE_TITLE from '@salesforce/label/c.RelatedUserStoryMetadata';
import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import NO_COLUMN_CONFIG_ERROR from '@salesforce/label/c.SprintWall_NoColumnError';
import ITEMS from '@salesforce/label/c.Items';

const RELATED_LIST_NAME = DATATABLE_TITLE;
const ORDER_BY = 'Name ASC, Id ASC NULLS LAST, CreatedDate';
const ICON_NAME = 'standard:all';
const NUMBER_OF_RECORDS_LIMIT = 8000;
const HIDE_DEFAULT_COLUMNS_ACTION = true;
const SORTABLE = true;
const ENABLE_INLINE_EDITING = false;
const SEARCHABLE = true;
const FILTERABLE = false;
const DEFAULT_SORT_FIELD = USER_STORY_FIELD.fieldApiName.replace('__c', '__r.LinkName');
const DEFAULT_SORT_DIRECTION = 'asc';
const KEY_FIELD = 'Id';

const CLASSIC_COLUMNS = [
    { label: 'Name', fieldName: 'n', type: 'text' },
    { label: 'Type', fieldName: 't', type: 'text' },
    { label: 'Retrieve Only', fieldName: 'r', type: 'boolean' },
    { label: 'Created by', fieldName: 'cb', type: 'text' },
    { label: 'Created date', fieldName: 'cd', type: 'text' }
];

if (!String.format) {
    String.format = function (format) {
        var args = Array.prototype.slice.call(arguments, 1);
        return format.replace(/{(\d+)}/g, function (match, number) {
            return typeof args[number] !== 'undefined' ? args[number] : match;
        });
    };
}

export const label = {
    ITEMS,
    FETCH_DATA_ERROR,
    RELATED_LIST_NAME,
    NO_COLUMN_CONFIG_ERROR
};

export const schema = {
    USER_STORY_METADATA: USER_STORY_METADATA.objectApiName,
    USER_STORY_FIELD: USER_STORY_FIELD.fieldApiName
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
    CLASSIC_COLUMNS,
    ICON_NAME
};