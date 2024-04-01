import NAME_FIELD from '@salesforce/schema/User_Story__c.Name';
import GIT_OPERATION_FIELD from '@salesforce/schema/Git_Org_Commit__c.Git_Operation__c';
import IS_SUCCESS_FIELD from '@salesforce/schema/Copado_Notification__c.isSuccess__c';
import IS_FINISHED_FIELD from '@salesforce/schema/Copado_Notification__c.isFinished__c';
import STATUS_FIELD from '@salesforce/schema/Copado_Notification__c.status__c';

import LOADING from '@salesforce/label/c.LOADING';
import USB_GO_BACK_USER_STORY from '@salesforce/label/c.USB_GO_BACK_USER_STORY';

import copadoUtils from 'c/copadocoreUtils';

export const schema = {
    USER_STORY_OBJECT: NAME_FIELD.objectApiName,
    NAME_FIELD: NAME_FIELD.fieldApiName,
    GIT_OPERATION_FIELD: GIT_OPERATION_FIELD.fieldApiName,
    IS_SUCCESS_FIELD: IS_SUCCESS_FIELD.fieldApiName,
    IS_FINISHED_FIELD: IS_FINISHED_FIELD.fieldApiName,
    STATUS_FIELD: STATUS_FIELD.fieldApiName,
    // Note: Platform Events aren't supported for import
    PAYLOAD_FIELD: copadoUtils.namespace + 'Payload__c',
    PUBLISHER_CODE_FIELD: copadoUtils.namespace + 'Publisher_Code__c',
    TOPIC_URI_FIELD: copadoUtils.namespace + 'Topic_Uri__c'
};

export const constants = {
    namespace: copadoUtils.namespace,
    LOADING,
    USB_GO_BACK_USER_STORY,
    COMPLETED: 'Completed',
    STARTED: 'Started',
    FIELDSET: copadoUtils.namespace + 'User_Story_Waiting_Page',
    COMMIT_FILES: 'Commit Files',
    FULL_PROFILES_PERMISSION_SETS: 'Full Profiles & Permission Sets',
    DESTRUCTIVE_CHANGES: 'Destructive Changes',
    COPADO_BACKEND: 'Copado Backend',
    CHECK_ICON: 'utility:check',
    START_ICON: 'utility:macros',
    WARNING_ICON: 'utility:warning',
    FINISHED_ICON: 'utility:multi_select_checkbox',
    TOPIC_URI: '/events/copado/v1/commit/'
};