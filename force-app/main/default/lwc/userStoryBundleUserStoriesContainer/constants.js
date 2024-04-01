import BUNDLED_STORY from '@salesforce/schema/Bundled_Story__c';
import PACKAGE_VERSION_FIELD from '@salesforce/schema/Bundled_Story__c.Package_Version__c';
import USER_STORY_FIELD from '@salesforce/schema/Bundled_Story__c.User_Story__c';
import PACKAGE_VERSION_STATUS_FIELD from '@salesforce/schema/Artifact_Version__c.Status__c';

import Fetch_Columns_Config_Error from '@salesforce/label/c.Fetch_Columns_Config_Error';
import Fetch_Data_Error from '@salesforce/label/c.Fetch_Data_Error';
import Add_User_Stories from '@salesforce/label/c.ManageUserStories';
import Remove_User_Stories from '@salesforce/label/c.Remove_User_Stories';
import User_Stories_Added_Message from '@salesforce/label/c.User_Stories_Added_Message';
import User_Stories_Table_Header from '@salesforce/label/c.User_Stories';

export const label = {
    Fetch_Columns_Config_Error,
    Fetch_Data_Error,
    Add_User_Stories,
    Remove_User_Stories,
    User_Stories_Added_Message,
    User_Stories_Table_Header
};

export const schema = {
    BUNDLED_STORY,
    PACKAGE_VERSION_FIELD,
    USER_STORY_FIELD,
    PACKAGE_VERSION_STATUS_FIELD
};