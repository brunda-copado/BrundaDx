import No_Credentials_For_Persona from '@salesforce/label/c.No_Credentials_For_Persona';
import Start_Sharing_Credentials_Now from '@salesforce/label/c.Start_Sharing_Credentials_Now';
import Share_Credential from '@salesforce/label/c.Share_Credential';
import Org_Credentials from '@salesforce/label/c.ORG_CREDENTIALS';
import Credential_Settings_Subtitle from '@salesforce/label/c.Credential_Settings_Subtitle';
import Share_Credentials from '@salesforce/label/c.Share_Credentials';
import Share_Credentials_Subtitle from '@salesforce/label/c.Share_Credentials_Subtitle';
import Credentials_Info_Message from '@salesforce/label/c.Credentials_Info_Message';
import More_Info from '@salesforce/label/c.More_Info';
import Refresh from '@salesforce/label/c.REFRESH';
import Cancel from '@salesforce/label/c.Cancel';
import Access_Level from '@salesforce/label/c.Access_Level';
import Change_Access_Level from '@salesforce/label/c.Change_Access_Level';
import Stop_Sharing from '@salesforce/label/c.Stop_Sharing';
import Read_Write from '@salesforce/label/c.Read_Write';
import Read_Only from '@salesforce/label/c.Read_Only';

import CREDENTIAL_OBJECT from '@salesforce/schema/Org__c';
import NAME_FIELD from '@salesforce/schema/Org__c.Name';
import ID_FIELD from '@salesforce/schema/Org__c.Id';
import ENVIRONMENT_FIELD from '@salesforce/schema/Org__c.Environment__c';
import PLATFORM_FIELD from '@salesforce/schema/Org__c.Platform__c';
import ORG_TYPE_FIELD from '@salesforce/schema/Org__c.Org_Type__c';
import ENVIRONMENT_NAME_FIELD from '@salesforce/schema/Environment__c.Name';

export const label = {
    No_Credentials_For_Persona,
    Start_Sharing_Credentials_Now,
    Share_Credential,
    Org_Credentials,
    Credential_Settings_Subtitle,
    Share_Credentials,
    Share_Credentials_Subtitle,
    Credentials_Info_Message,
    More_Info,
    Refresh,
    Cancel,
    Access_Level,
    Change_Access_Level,
    Stop_Sharing,
    Read_Write,
    Read_Only
};

export const schema = {
    CREDENTIAL_OBJECT,
    ID_FIELD,
    NAME_FIELD,
    ENVIRONMENT_FIELD,
    PLATFORM_FIELD,
    ORG_TYPE_FIELD,
    ENVIRONMENT_NAME_FIELD
};

export const ACCESS_LEVEL = 'AccessLevel';
export const EDIT_ACCESS_LEVEL = 'Edit';