import COMMIT_DATA from '@salesforce/label/c.Commit_Data';
import CANCEL from '@salesforce/label/c.Cancel';
import SELECT_DATA_SOURCE from '@salesforce/label/c.Select_Data_Source';
import ENVIRONMENT_BASED_ON_DATA_TEMPLATE from '@salesforce/label/c.Environment_Based_On_Data_Template';
import DATA_SET_LABEL from '@salesforce/label/c.Data_Set';
import REVIEW_DATA_FILTERS from '@salesforce/label/c.Review_Data_Filters';
import COMPLETE_ALL_FIELDS from '@salesforce/label/c.Complete_All_Fields';
import NO_ORG_CREDENTIAL_ON_USER_STORY from '@salesforce/label/c.NO_ORG_CREDENTIAL_ON_USER_STORY';
import COPADO_TIPS_TITLE from '@salesforce/label/c.Copado_Pro_Query_Tips';
import COPADO_TIPS1 from '@salesforce/label/c.Data_Template_Query_Tip_1';
import COPADO_TIPS2 from '@salesforce/label/c.Data_Template_Query_Tip_2';
import COPADO_TIPS3 from '@salesforce/label/c.Data_Template_Query_Tip_3';
import COPADO_TIPS4 from '@salesforce/label/c.Data_Template_Query_Tip_4';
import COMMIT_DATA_NOT_AVAILBALE_TITLE from '@salesforce/label/c.CommitDataNotAvailableTitle';
import COMMIT_DATA_NOT_AVAILBALE_BODY from '@salesforce/label/c.CommitDataNotAvailableBody';
import COMMIT_DATA_INVALID_ORG_MESSAGE from '@salesforce/label/c.CommitDataInvalidOrgMessage'
import CREDENTAIL from '@salesforce/label/c.Org_Credential'

import DATA_SET from '@salesforce/schema/Data_Set__c';
import DATA_SET_DATA_TEMPLATE from '@salesforce/schema/Data_Set__c.Data_Template__c';

import USER_STORY_DATA_COMMIT from '@salesforce/schema/User_Story_Data_Commit__c';
import USER_STORY_DATA_COMMIT_COMMIT_MESSAGE from '@salesforce/schema/User_Story_Data_Commit__c.Commit_Message__c';
import USER_STORY_DATA_COMMIT_DATA_SET from '@salesforce/schema/User_Story_Data_Commit__c.Data_Set__c';

import USER_STORY from '@salesforce/schema/User_Story__c';
import USER_STORY_NAME from '@salesforce/schema/User_Story__c.Name';
import USER_STORY_ORG_CREDENTIAL from '@salesforce/schema/User_Story__c.Org_Credential__c';

import DATA_TEMPLATE_MAIN_OBJECT from '@salesforce/schema/Data_Template__c.Main_Object__c';

import HIDE_LIGHTNING_HEADER from '@salesforce/resourceUrl/HideLightningHeader';

export const label = {
    COMMIT_DATA,
    CANCEL,
    SELECT_DATA_SOURCE,
    ENVIRONMENT_BASED_ON_DATA_TEMPLATE,
    DATA_SET_LABEL,
    REVIEW_DATA_FILTERS,
    COMPLETE_ALL_FIELDS,
    NO_ORG_CREDENTIAL_ON_USER_STORY,
    COPADO_TIPS_TITLE,
    COPADO_TIPS1,
    COPADO_TIPS2,
    COPADO_TIPS3,
    COPADO_TIPS4,
    COMMIT_DATA_NOT_AVAILBALE_TITLE,
    COMMIT_DATA_NOT_AVAILBALE_BODY,
    COMMIT_DATA_INVALID_ORG_MESSAGE,
    CREDENTAIL
};

export const schema = {
    DATA_SET,
    DATA_SET_DATA_TEMPLATE,
    USER_STORY_DATA_COMMIT,
    USER_STORY_DATA_COMMIT_COMMIT_MESSAGE,
    USER_STORY_DATA_COMMIT_DATA_SET,
    USER_STORY,
    USER_STORY_NAME,
    USER_STORY_ORG_CREDENTIAL,
    DATA_TEMPLATE_MAIN_OBJECT
};

export const resource = {
    HIDE_LIGHTNING_HEADER
};

export const sourceOptions = [
    { value: 'ENVIRONMENT', label: label.ENVIRONMENT_BASED_ON_DATA_TEMPLATE },
    { value: 'DATASET', label: label.DATA_SET_LABEL }
];