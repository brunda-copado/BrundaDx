import DeleteBranchesWarning from '@salesforce/label/c.DELETE_BRANCHES_WARNING';
import NoDataToDisplay from '@salesforce/label/c.NODATATODISPLAY';
import Branches from '@salesforce/label/c.BRANCHES';
import Refresh from '@salesforce/label/c.REFRESH';
import DeleteSelectedBranches from '@salesforce/label/c.DELETE_SELECTED_BRANCHES';
import LastModifiedDate from '@salesforce/label/c.Last_Modified_Date';
import GitDirectory from '@salesforce/label/c.Git_Directory';
import BranchName from '@salesforce/label/c.Branch_Name';
import SELECT_ATLEAST_ONE_BRANCH from '@salesforce/label/c.SELECT_ATLEAST_ONE_BRANCH';
import GIT_BRANCH_DELETE_ERROR_MESSAGE from '@salesforce/label/c.Git_Branch_Delete_Error_Message';
import GIT_BRANCH_REFRESH_ERROR_MESSAGE from '@salesforce/label/c.Git_Branch_Refresh_Error_Message';
import ITEMS from '@salesforce/label/c.Items';
import SUCCESS_BRANCH_DELETE_RETRIEVE_MESSAGE from '@salesforce/label/c.Success_Branch_Delete_Retrieve_Message';
import REFRESHING_BRANCHES_MESSAGE from '@salesforce/label/c.REFRESHING_BRANCHES_MESSAGE';
import DELETING_BRANCHES_MESSAGE from '@salesforce/label/c.DELETING_BRANCHES_MESSAGE';
import RETRIEVED from '@salesforce/label/c.RETRIEVED';
import DELETED from '@salesforce/label/c.DELETED';

import GIT_REPOSITORY from '@salesforce/schema/Git_Repository__c';
import BRANCH_BASE_URL_FIELD from '@salesforce/schema/Git_Repository__c.Branch_Base_URL__c';
import NAME_FIELD from '@salesforce/schema/Git_Repository__c.Name';

import COPADO_NOTIFICATION from '@salesforce/schema/Copado_Notification__c';
import COPADO_NOTIFICATION_IS_FINISHED from '@salesforce/schema/Copado_Notification__c.isFinished__c';
import COPADO_NOTIFICATION_IS_SUCCESS from '@salesforce/schema/Copado_Notification__c.isSuccess__c';
import COPADO_NOTIFICATION_STATUS from '@salesforce/schema/Copado_Notification__c.status__c';
import COPADO_NOTIFICATION_PARENT_ID from '@salesforce/schema/Copado_Notification__c.ParentId__c';

import TIME_ZONE from '@salesforce/i18n/timeZone';

export const label = {
    ITEMS,
    Refresh,
    Branches,
    BranchName,
    GitDirectory,
    NoDataToDisplay,
    LastModifiedDate,
    DeleteBranchesWarning,
    DeleteSelectedBranches,
    SELECT_ATLEAST_ONE_BRANCH,
    GIT_BRANCH_DELETE_ERROR_MESSAGE,
    GIT_BRANCH_REFRESH_ERROR_MESSAGE,
    SUCCESS_BRANCH_DELETE_RETRIEVE_MESSAGE,
    REFRESHING_BRANCHES_MESSAGE,
    DELETING_BRANCHES_MESSAGE,
    RETRIEVED,
    DELETED
};

export const schema = {
    GIT_REPOSITORY,
    NAME_FIELD,
    BRANCH_BASE_URL_FIELD,
    COPADO_NOTIFICATION,
    COPADO_NOTIFICATION_IS_FINISHED,
    COPADO_NOTIFICATION_IS_SUCCESS,
    COPADO_NOTIFICATION_STATUS,
    COPADO_NOTIFICATION_PARENT_ID
};

export const columns = [
    { label: label.BranchName, fieldName: 'name', type: 'text', sortable: true, hideDefaultActions: true },
    { label: label.GitDirectory, fieldName: 'GitDirectory', type: 'url', hideDefaultActions: true },
    {
        label: label.LastModifiedDate,
        fieldName: 'LastModifiedDate',
        type: 'date',
        sortable: true,
        hideDefaultActions: true,
        typeAttributes: {
            month: '2-digit',
            day: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            timezone: TIME_ZONE
        }
    }
];