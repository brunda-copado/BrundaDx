import SOURCE_ORG_FIELD from '@salesforce/schema/Data_Template__c.Template_Source_Org__c';
import MAIN_OBJECT_FIELD from '@salesforce/schema/Data_Template__c.Main_Object__c';
import DATA_DEPLOYER_PERMISSION_ISSUE from '@salesforce/label/c.DataDeployerPermissionsIssue';
import DD_LICENSE_RESTRICTION from '@salesforce/label/c.DD_License_Restriction';
import ORG_CRED_INVALID from '@salesforce/label/c.OrgCredentialInvalid';
import NO_ACCESS_TO_CREDENTIAL from '@salesforce/label/c.NoAccessToCredential';
import DATA_TEMPLATE_INACTIVE_ERROR from '@salesforce/label/c.DataTemplateInactiveRelatedTemplate';
export const schema = {
    SOURCE_ORG_FIELD,
    MAIN_OBJECT_FIELD
};

export const label = {
    DATA_DEPLOYER_PERMISSION_ISSUE,
    DD_LICENSE_RESTRICTION,
    ORG_CRED_INVALID,
    NO_ACCESS_TO_CREDENTIAL,
    DATA_TEMPLATE_INACTIVE_ERROR
};