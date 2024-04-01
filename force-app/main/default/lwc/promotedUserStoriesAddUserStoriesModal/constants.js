import Fetch_Columns_Config_Error from '@salesforce/label/c.Fetch_Columns_Config_Error';
import Fetch_Data_Error from '@salesforce/label/c.Fetch_Data_Error';
import Save from '@salesforce/label/c.Save';
import Cancel from '@salesforce/label/c.Cancel';
import Refresh from '@salesforce/label/c.REFRESH';
import Items from '@salesforce/label/c.Items';
import Add_User_Stories from '@salesforce/label/c.ManageUserStories';
import User_stories_added_successfully from '@salesforce/label/c.User_stories_added_successfully';
import Add_User_Stories_Info_Message from '@salesforce/label/c.Add_User_Stories_Info_Message';
import Add_User_Stories_Empty_Illustration_Title from '@salesforce/label/c.Add_User_Stories_Empty_Illustration_Title';
import Add_User_Stories_Empty_Illustration_Body from '@salesforce/label/c.Add_User_Stories_Empty_Illustration_Body';

import USER_STORY from '@salesforce/schema/User_Story__c';
import DEVELOPER_FIELD from '@salesforce/schema/User_Story__c.Developer__c';

export const label = {
    Save,
    Cancel,
    Refresh,
    Add_User_Stories,
    Items,
    Fetch_Data_Error,
    Fetch_Columns_Config_Error,
    User_stories_added_successfully,
    Add_User_Stories_Info_Message,
    Add_User_Stories_Empty_Illustration_Title,
    Add_User_Stories_Empty_Illustration_Body
};

export const schema = {
    USER_STORY,
    DEVELOPER_FIELD
};