import Fetch_Columns_Config_Error from '@salesforce/label/c.Fetch_Columns_Config_Error';
import Fetch_Data_Error from '@salesforce/label/c.Fetch_Data_Error';
import Save from '@salesforce/label/c.Save';
import Cancel from '@salesforce/label/c.Cancel';
import Refresh from '@salesforce/label/c.REFRESH';
import Add_User_Stories from '@salesforce/label/c.ManageUserStories';
import USB_No_User_Story from '@salesforce/label/c.USB_No_User_Story';
import USB_Add_User_Story_Modal_Info from '@salesforce/label/c.USB_Add_User_Story_Modal_Info';

import USER_STORY from '@salesforce/schema/User_Story__c';
import DEVELOPER_FIELD from '@salesforce/schema/User_Story__c.Developer__c';
import ID_FIELD from '@salesforce/schema/User_Story__c.Id';

const ORDER_BY = 'LastModifiedDate DESC NULLS LAST';
const NUMBER_OF_RECORDS_LIMIT = 8000;

export const label = {
    Fetch_Columns_Config_Error,
    Fetch_Data_Error,
    Save,
    Cancel,
    Refresh,
    Add_User_Stories,
    USB_No_User_Story,
    USB_Add_User_Story_Modal_Info
};

export const schema = {
    USER_STORY,
    DEVELOPER_FIELD,
    ID_FIELD
};

export const constants = {
    ORDER_BY,
    NUMBER_OF_RECORDS_LIMIT
};