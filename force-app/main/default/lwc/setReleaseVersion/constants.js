import Error from '@salesforce/label/c.ERROR';
import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';
import Set_Release_Version from '@salesforce/label/c.Set_Release_Version';
import Info from '@salesforce/label/c.Set_Release_Version_Info';
import Commit_Page_Info from '@salesforce/label/c.Commit_Page_Info';
import Previous_Release_Information from '@salesforce/label/c.Previous_Release_Information';
import Previous_Release from '@salesforce/label/c.Previous_Release';
import Previous_Release_Helptext from '@salesforce/label/c.Previous_Release_Helptext';
import Previous_Release_Placeholder from '@salesforce/label/c.Previous_Release_Placeholder';
import Previous_Release_Version from '@salesforce/label/c.Previous_Release_Version';
import Previous_Release_Version_Helptext from '@salesforce/label/c.Previous_Release_Version_Helptext';
import New_Release_Information from '@salesforce/label/c.New_Release_Information';
import Version_Type from '@salesforce/label/c.Version_Type';
import Version_Type_Helptext from '@salesforce/label/c.Version_Type_Helptext';
import New_Release_Version from '@salesforce/label/c.New_Release_Version';
import New_Release_Version_Helptext from '@salesforce/label/c.New_Release_Version_Helptext';
import Project_label from '@salesforce/label/c.Project';
import Status_label from '@salesforce/label/c.STATUS';
import Cancel from '@salesforce/label/c.Cancel';
import Save from '@salesforce/label/c.Save';
import Update_Record_Error_Title from '@salesforce/label/c.Update_Record_Error_Title';
import SUCCESS from '@salesforce/label/c.SUCCESS';
import Set_Release_Success from '@salesforce/label/c.Set_Release_Success';
import Version_Type_Major from '@salesforce/label/c.Version_Type_Major';
import Version_Type_Minor from '@salesforce/label/c.Version_Type_Minor';
import Version_Type_Patch from '@salesforce/label/c.Version_Type_Patch';
import No_results from '@salesforce/label/c.No_results';
import RELEASE_NOT_FOUND from '@salesforce/label/c.RELEASE_NOT_FOUND';

import RELEASE_OBJECT from '@salesforce/schema/Release__c';
import RELEASE_ID from '@salesforce/schema/Release__c.Id';
import VERSIONTYPE from '@salesforce/schema/Release__c.Type__c';
import VERSION from '@salesforce/schema/Release__c.Version__c';
import STATUS from '@salesforce/schema/Release__c.Status__c';
import PROJECT from '@salesforce/schema/Release__c.Project__c';
import PROJECT_NAME from '@salesforce/schema/Release__c.Project__r.Name';

export const labels = {
    Error,
    Error_Searching_Records,
    Set_Release_Version,
    Info,
    Commit_Page_Info,
    Previous_Release_Information,
    Previous_Release,
    Previous_Release_Helptext,
    Previous_Release_Placeholder,
    Previous_Release_Version,
    Previous_Release_Version_Helptext,
    New_Release_Information,
    Version_Type,
    Version_Type_Helptext,
    New_Release_Version,
    New_Release_Version_Helptext,
    Project_label,
    Status_label,
    Cancel,
    Save,
    Update_Record_Error_Title,
    SUCCESS,
    Set_Release_Success,
    Version_Type_Major,
    Version_Type_Minor,
    Version_Type_Patch,
    No_results,
    RELEASE_NOT_FOUND
};

export const schema = {
    RELEASE_OBJECT,
    RELEASE_ID,
    VERSIONTYPE,
    VERSION,
    STATUS,
    PROJECT,
    PROJECT_NAME
};