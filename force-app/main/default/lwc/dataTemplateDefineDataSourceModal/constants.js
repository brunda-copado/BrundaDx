import DEFINE_DATA_SOURCE from '@salesforce/label/c.DefineDataSource';
import ORG_NOT_AUTHENTICATED from '@salesforce/label/c.OrgNotAuthenticated';
import MAIN_OBJECT from '@salesforce/label/c.MainObject';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import COMPLETE_ALL_FIELDS from '@salesforce/label/c.Complete_All_Fields';
import DATA_TEMPLATE_SUCCESS_UPDATE from '@salesforce/label/c.DataTemplateSuccessUpdate';
import MAIN_OBJECT_HELP_TEXT from '@salesforce/label/c.Main_Object_Tooltip';
import COMPLETE_THIS_FIELD from '@salesforce/label/c.CompleteThisField';

import DATA_TEMPLATE from '@salesforce/schema/Data_Template__c';
import ID_FIELD from '@salesforce/schema/Data_Template__c.Id';
import SOURCE_ORG_FIELD from '@salesforce/schema/Data_Template__c.Template_Source_Org__c';
import MAIN_OBJECT_FIELD from '@salesforce/schema/Data_Template__c.Main_Object__c';

export const label = {
    DEFINE_DATA_SOURCE,
    ORG_NOT_AUTHENTICATED,
    MAIN_OBJECT,
    CANCEL,
    SAVE,
    COMPLETE_ALL_FIELDS,
    DATA_TEMPLATE_SUCCESS_UPDATE,
    MAIN_OBJECT_HELP_TEXT,
    COMPLETE_THIS_FIELD
};

export const schema = {
    DATA_TEMPLATE,
    ID_FIELD,
    SOURCE_ORG_FIELD,
    MAIN_OBJECT_FIELD
};