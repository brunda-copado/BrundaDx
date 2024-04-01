import USER_STORY from '@salesforce/schema/User_Story__c';
import SPRINT_FIELD from '@salesforce/schema/User_Story__c.Sprint__c';
import TEAM_FIELD_SET_NAME_FIELD from '@salesforce/schema/Sprint__c.Team__r.Sprint_Wall_FieldSet_Name__c';

import SPRINT_WALL_TITLE from '@salesforce/label/c.SprintWall_Title';
import VIEW from '@salesforce/label/c.VIEW';
import EDIT from '@salesforce/label/c.EDIT';
import DELETE from '@salesforce/label/c.DELETE';
import RELATED_LIST_ERROR from '@salesforce/label/c.Related_List_Error';
import FETCH_COLUMN_CONFIG_ERROR from '@salesforce/label/c.Fetch_Columns_Config_Error';
import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import SPRINT_WALL_ALERT_COMMUNICATION_ID from '@salesforce/label/c.SprintWallAlertCommunicationId';
import NO_COLUMN_CONFIG_ERROR from '@salesforce/label/c.SprintWall_NoColumnError';
import CE_LICENSE_RESTRICTION from '@salesforce/label/c.CE_License_Restriction';
import CCM_OR_CAD_LICENSE from '@salesforce/label/c.CCM_or_CAD_License';
import WARNING from '@salesforce/label/c.WARNING';
import DIFFERENT_TEAMS_WARNING from '@salesforce/label/c.SprintWall_DifferentTeamsWarning';

import copadoUtils from 'c/copadocoreUtils';

const ROW_ACTIONS = [
    { label: VIEW, name: 'view' },
    { label: EDIT, name: 'edit' },
    { label: DELETE, name: 'delete' }
];
const FIELD_SET_NAME = 'Sprint_Wall_Columns';
const RELATED_LIST_NAME = SPRINT_WALL_TITLE;
const ORDER_BY = 'Name ASC, Id ASC NULLS LAST, CreatedDate';
const NUMBER_OF_RECORDS_LIMIT = 10000;
const HIDE_DEFAULT_COLUMNS_ACTION = true;
const SORTABLE = true;
const ENABLE_INLINE_EDITING = true;
const SEARCHABLE = true;
const FILTERABLE = false;
const PICKLIST = 'picklist';
const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const LICENSE_RESTRICTION_ERROR = WARNING + ': ' + CE_LICENSE_RESTRICTION.replace('__License__', CCM_OR_CAD_LICENSE);
const TEAM_OBJECT_RELATION = 'Team__r';
const TEAM_FIELD_SET_FIELD_NAME = 'Sprint_Wall_FieldSet_Name__c';
const UNDEFINED = 'undefined';
const TEAM_ALERT_ID = 'teamAlertId';
const ALERT_OPERATION_ADD = 'add';
const ALERT_OPERATION_REMOVE = 'remove';

if (!String.format) {
    String.format = function (format) {
        var args = Array.prototype.slice.call(arguments, 1);
        return format.replace(/{(\d+)}/g, function (match, number) {
            return typeof args[number] !== 'undefined' ? args[number] : match;
        });
    };
}
export const getNamespace = () => {
    const sprintAPIName = SPRINT_FIELD.fieldApiName;
    return sprintAPIName.replace('Sprint__c', '');
};

export const schema = {
    USER_STORY: USER_STORY.objectApiName,
    SPRINT_FIELD: SPRINT_FIELD.fieldApiName,
    FIELD_SET_NAME,
    NAMESPACE: copadoUtils.namespace,
    TEAM_FIELD_SET_NAME_FIELD
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
    ROW_ACTIONS,
    RELATED_LIST_NAME,
    PICKLIST,
    ERROR_VARIANT,
    SPRINT_WALL_ALERT_COMMUNICATION_ID,
    NO_COLUMN_CONFIG_ERROR,
    LICENSE_RESTRICTION_ERROR,
    DIFFERENT_TEAMS_WARNING,
    WARNING_VARIANT,
    TEAM_OBJECT_RELATION,
    TEAM_FIELD_SET_FIELD_NAME,
    UNDEFINED,
    TEAM_ALERT_ID,
    ALERT_OPERATION_ADD,
    ALERT_OPERATION_REMOVE
};