import JOB_EXECUTION from '@salesforce/schema/JobExecution__c';
import ID_FIELD from '@salesforce/schema/JobExecution__c.Id';
import CREATED_DATE_FIELD from '@salesforce/schema/JobExecution__c.CreatedDate';

import JOB_EXECUTIONS from '@salesforce/label/c.Job_Executions';
import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import NO_COLUMN_CONFIG_ERROR from '@salesforce/label/c.SprintWall_NoColumnError';
import ITEMS from '@salesforce/label/c.Items';

const ORDER_BY = 'CreatedDate DESC';
const ICON_NAME = 'custom:custom44';
const NUMBER_OF_RECORDS_LIMIT = 100;
const HIDE_DEFAULT_COLUMNS_ACTION = true;
const SORTABLE = true;
const ENABLE_INLINE_EDITING = false;
const SEARCHABLE = true;
const FILTERABLE = false;
const DEFAULT_SORT_FIELD = CREATED_DATE_FIELD.fieldApiName;
const DEFAULT_SORT_DIRECTION = 'desc';
const KEY_FIELD = 'Id';

export const label = {
    ITEMS,
    FETCH_DATA_ERROR,
    JOB_EXECUTIONS,
    NO_COLUMN_CONFIG_ERROR
};

export const schema = {
    JOB_EXECUTION,
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