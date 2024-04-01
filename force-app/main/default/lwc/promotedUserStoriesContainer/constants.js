import Fetch_Columns_Config_Error from '@salesforce/label/c.Fetch_Columns_Config_Error';
import FETCH_DATA_ERROR from '@salesforce/label/c.Fetch_Data_Error';
import Add_User_Stories from '@salesforce/label/c.ManageUserStories';
import Promoted_User_Stories from '@salesforce/label/c.Promoted_User_Stories';
import Remove_User_Stories from '@salesforce/label/c.Remove_User_Stories';
import ITEMS from '@salesforce/label/c.Items';

import PROMOTED_USER_STORY from '@salesforce/schema/Promoted_User_Story__c';
import PROMOTION_FIELD from '@salesforce/schema/Promoted_User_Story__c.Promotion__c';
import USER_STORY_FIELD from '@salesforce/schema/Promoted_User_Story__c.User_Story__c';

import VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';
import CONTENT_SIZE_FIELD from '@salesforce/schema/ContentVersion.ContentSize';
import CONTENT_DOCUMENT_ID_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.Id';
import TITLE_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.Title';
import LATEST_PUBLISHED_VERSION_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocument.LatestPublishedVersionId';
import OWNER_ID from '@salesforce/schema/ContentDocumentLink.ContentDocument.OwnerId';

import Id from '@salesforce/user/Id';

export const label = {
    FETCH_DATA_ERROR,
    Fetch_Columns_Config_Error,
    Add_User_Stories,
    Promoted_User_Stories,
    Remove_User_Stories,
    ITEMS
};

export const schema = {
    PROMOTED_USER_STORY,
    PROMOTION_FIELD,
    USER_STORY_FIELD,

    TITLE_FIELD,
    VERSION_DATA_FIELD,
    CONTENT_SIZE_FIELD,
    LATEST_PUBLISHED_VERSION_FIELD,
    OWNER_ID,
    CONTENT_DOCUMENT_ID_FIELD,
    RESULT_DOC_RELATIONSHIP: 'ContentDocumentLinks'
};

export const constants = {
    CURRENT_USER_ID: Id,
    IGNORED_CHANGES_FILE_NAME: 'Ignored changes',
    MAX_FILE_SIZE_SUPPORTED: '5242880' // 5 MB = 5,242,880 Bytes (Binary)
};