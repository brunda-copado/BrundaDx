import DATA_DEPLOYER_PERMISSION_ISSUE from '@salesforce/label/c.DataDeployerPermissionsIssue';
import FORMULA_CONFIGURATION_TITLE from '@salesforce/label/c.Record_Matching_Formula_Configuration';
import TIPS_TITLE from '@salesforce/label/c.Copado_Pro_Formula_Tips';
import TIP1 from '@salesforce/label/c.ADD_Record_Matching_Tip_1';
import TIP2 from '@salesforce/label/c.ADD_Record_Matching_Tip_2';
import TIP3 from '@salesforce/label/c.ADD_Record_Matching_Tip_3';
import TIP4 from '@salesforce/label/c.ADD_Record_Matching_Tip_4';

import OBJECT from '@salesforce/schema/Record_Matching_Formula__c.Object__c';
import SCHEMA_CREDENTIAL from '@salesforce/schema/Record_Matching_Formula__c.Configuration_Source_Org__c';
import FIELD1 from '@salesforce/schema/Record_Matching_Formula__c.Field_1__c';
import RMF_NO_ACCESS_TO_CREDENTIAL from '@salesforce/label/c.SchemaCredentialAccessMessage';
import ORG_CRED_INVALID from '@salesforce/label/c.OrgCredentialInvalid';
import DD_LICENSE_RESTRICTION_RMFORMULA from '@salesforce/label/c.DD_License_Restriction_RMFormula';
const label = {
    DATA_DEPLOYER_PERMISSION_ISSUE,
    TIPS_TITLE,
    TIP1,
    TIP2,
    TIP3,
    TIP4,
    RMF_NO_ACCESS_TO_CREDENTIAL,
    ORG_CRED_INVALID,
    DD_LICENSE_RESTRICTION_RMFORMULA,
    FORMULA_CONFIGURATION_TITLE
}

const schema = {
    OBJECT,
    SCHEMA_CREDENTIAL,
    FIELD1
}

export { label, schema }