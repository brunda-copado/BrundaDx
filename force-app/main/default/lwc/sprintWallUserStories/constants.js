import SPRINT_FIELD from '@salesforce/schema/User_Story__c.Sprint__c';

import VIEW_IN_KANBAN from '@salesforce/label/c.ViewInKanban';
import EDIT_STORIES from '@salesforce/label/c.EditStories';
import NEW from '@salesforce/label/c.NEW';
import REFRESH from '@salesforce/label/c.REFRESH';
import VIEW_ALL from '@salesforce/label/c.View_All';
import ITEMS from '@salesforce/label/c.Items';
import SELECTED from '@salesforce/label/c.SELECTED';
import UPDATE_RECORD_ERROR_TITLE from '@salesforce/label/c.Update_Record_Error_Title';
import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import SELECT_ATLEAST_ONE_RECORD_ERROR from '@salesforce/label/c.SelectAtleastOneRecord';
import SPRINT_WALL_ALERT_COMMUNICATION_ID from '@salesforce/label/c.SprintWallAlertCommunicationId';

const VIEW_BUTTON_NAME = 'view';
const EDIT_BUTTON_NAME = 'edit';
const DELETE_BUTTON_NAME = 'delete';
const VIEW_IN_KANBAN_BUTTON_NAME = 'viewInKanban';
const NEW_BUTTON_NAME = 'new';
const VIEW_ALL_BUTTON_NAME = 'viewall';
const NUMBER_OF_RECORDS_LIMIT = 10;
const ERROR_VARIANT = 'error';
const DEFAULT_SORT_FIELD = 'LinkName';
const DEFAULT_SORT_DIRECTION = 'asc';
const KEY_FIELD = 'Id';
const ITEM = ITEMS.slice(0, -1);

export const label = {
    VIEW_IN_KANBAN,
    EDIT_STORIES,
    NEW,
    REFRESH,
    VIEW_ALL,
    ITEM,
    ITEMS,
    ITEM_SELECTED: ITEM + ' ' + SELECTED,
    ITEMS_SELECTED: ITEMS + ' ' + SELECTED
};

export const schema = {
    SPRINT_FIELD: SPRINT_FIELD.fieldApiName
};

export const constants = {
    VIEW_BUTTON_NAME,
    VIEW_IN_KANBAN_BUTTON_NAME,
    EDIT_BUTTON_NAME,
    DELETE_BUTTON_NAME,
    NEW_BUTTON_NAME,
    VIEW_ALL_BUTTON_NAME,
    UPDATE_RECORD_ERROR_TITLE,
    NUMBER_OF_RECORDS_LIMIT,
    FETCH_DATA_ERROR,
    SELECT_ATLEAST_ONE_RECORD_ERROR,
    SPRINT_WALL_ALERT_COMMUNICATION_ID,
    ERROR_VARIANT,
    DEFAULT_SORT_FIELD,
    DEFAULT_SORT_DIRECTION,
    KEY_FIELD
};