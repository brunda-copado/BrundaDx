import USER_STORY from '@salesforce/schema/User_Story__c';
import USER_STORY_OWNER from '@salesforce/schema/User_Story__c.OwnerId';
import USER_STORY_RECORD_TYPE from '@salesforce/schema/User_Story__c.RecordTypeId';

import EDIT_STORIES from '@salesforce/label/c.EditStories';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import UPDATE_RECORD_ERROR_TITLE from '@salesforce/label/c.Update_Record_Error_Title';
import FETCH_COLUMN_CONFIG_ERROR from '@salesforce/label/c.Fetch_Columns_Config_Error';
import NO_COLUMN_CONFIG_ERROR from '@salesforce/label/c.SprintWall_NoColumnError';
import ERROR_SEARCHING_RECORDS from '@salesforce/label/c.Error_Searching_Records';
import ENTER_VALUE_FOR_UPDATE_ERROR from '@salesforce/label/c.EnterValueForUpdate';

const FIELD_SET_NAME = 'SprintWall_MassUpdate';
const REFERENCE = 'reference';
const INFO_VARIANT = 'info';
const ERROR_VARIANT = 'error';
const NAME = 'Name';
const USER = 'User';
const OWNER_FIELD = USER_STORY_OWNER.fieldApiName;
const RECORD_TYPE_FIELD = USER_STORY_RECORD_TYPE.fieldApiName;
const CUSTOM_LOOKUPS = [OWNER_FIELD.toLowerCase()];
const NOT_ALLOWED_REFERENCE_FIELDS = [RECORD_TYPE_FIELD.toLowerCase()];

export const schema = {
    USER_STORY: USER_STORY.objectApiName,
    OWNER_FIELD,
    FIELD_SET_NAME,
    NAME,
    USER
};

export const label = {
    EDIT_STORIES,
    CANCEL,
    SAVE,
    ERROR_SEARCHING_RECORDS
};

export const constants = {
    UPDATE_RECORD_ERROR_TITLE,
    FETCH_COLUMN_CONFIG_ERROR,
    NO_COLUMN_CONFIG_ERROR,
    REFERENCE,
    ERROR_VARIANT,
    CUSTOM_LOOKUPS,
    NOT_ALLOWED_REFERENCE_FIELDS
};

export const infoAlert = {
    message: ENTER_VALUE_FOR_UPDATE_ERROR,
    variant: INFO_VARIANT,
    dismissible: false
};