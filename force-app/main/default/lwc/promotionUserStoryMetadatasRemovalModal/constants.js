import Remove_Changes from '@salesforce/label/c.Remove_Changes';
import Error_while_removing_changes from '@salesforce/label/c.Error_while_removing_changes';
import Changes_removed_successfully from '@salesforce/label/c.Changes_removed_successfully';
import Cancel from '@salesforce/label/c.Cancel';
import Close from '@salesforce/label/c.CLOSE';
import Confirm from '@salesforce/label/c.Confirm';
import Remove_Changes_Confirmation from '@salesforce/label/c.Remove_Changes_Confirmation';
import Remove_Changes_Warning from '@salesforce/label/c.Remove_Changes_Warning';
import Remove_Changes_Error from '@salesforce/label/c.Remove_All_Changes_Error';
import Remove_All_Changes_Error_Message from '@salesforce/label/c.Remove_All_Changes_Error_Message';
import Unable_to_remove_changes_body from '@salesforce/label/c.Unable_to_remove_changes_body';

import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';
import CONTENT_SIZE_FIELD from '@salesforce/schema/ContentVersion.ContentSize';
import TITLE_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.Title';
import LATEST_PUBLISHED_VERSION_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.LatestPublishedVersionId';

import USER_STORY_METADATA_TYPE_FIELD from '@salesforce/schema/User_Story_Metadata__c.Type__c';
import USER_STORY_METADATA_ACTION_FIELD from '@salesforce/schema/User_Story_Metadata__c.Action__c';
import USER_STORY_METADATA_API_NAME_FIELD from '@salesforce/schema/User_Story_Metadata__c.Metadata_API_Name__c';
import USER_STORY_METADATA_MODULE_DIRECTORY_FIELD from '@salesforce/schema/User_Story_Metadata__c.ModuleDirectory__c';
import USER_STORY_METADATA_USER_STORY_FIELD from '@salesforce/schema/User_Story_Metadata__c.User_Story__c';
import USER_STORY_NAME_FIELD from '@salesforce/schema/User_Story__c.Name';

export const label = {
    Remove_Changes,
    Error_while_removing_changes,
    Changes_removed_successfully,
    Cancel,
    Close,
    Confirm,
    Remove_Changes_Confirmation,
    Remove_Changes_Warning,
    FETCH_DATA_ERROR,
    Remove_Changes_Error,
    Remove_All_Changes_Error_Message,
    Unable_to_remove_changes_body
};

export const schema = {
    TITLE_FIELD,
    VERSION_DATA_FIELD,
    CONTENT_SIZE_FIELD,
    LATEST_PUBLISHED_VERSION_FIELD,
    USER_STORY_METADATA_TYPE_FIELD,
    USER_STORY_METADATA_ACTION_FIELD,
    USER_STORY_METADATA_API_NAME_FIELD,
    USER_STORY_METADATA_MODULE_DIRECTORY_FIELD,
    USER_STORY_METADATA_USER_STORY_FIELD,
    USER_STORY_NAME_FIELD,
    RESULT_DOC_RELATIONSHIP: 'ContentDocumentLinks'
};

export const constants = {
    IGNORED_CHANGES_FILE_NAME: 'Ignored changes',
    MAX_FILE_SIZE_SUPPORTED: '5242880' // 5 MB = 5,242,880 Bytes (Binary)
};