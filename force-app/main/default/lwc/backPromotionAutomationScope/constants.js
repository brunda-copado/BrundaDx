import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import CONFIGURE_SCOPE from '@salesforce/label/c.Configure_Scope';
import NO_SCOPE_DEFINED_BODY from '@salesforce/label/c.Back_Promotion_Illustration_Body';
import NO_SCOPE_DEFINED from '@salesforce/label/c.Back_Promotion_Illustration_Title';
import CLEAR_ALL from '@salesforce/label/c.Clear_All';
import INSUFFICIENT_PERMISSION from '@salesforce/label/c.No_necessary_permission_for_automation_rule';
import BACK_PROMOTION_AUTOMATION_SCOPE from '@salesforce/label/c.Back_Promotion_Automation_Scope';
import EXCLUDED_ENVIRONMENTS from '@salesforce/label/c.Excluded_Environments';
import INCLUDED_ENVIRONMENTS from '@salesforce/label/c.Included_Environments';
import EXCLUDED_ENVIRONMENTS_HELPTEXT from '@salesforce/label/c.Excluded_Environments_Helptext';
import BACK_PROMOTION_FIELD_LABEL from '@salesforce/label/c.Back_Promotion_Env_Label';
import BACK_PROMOTION_ERROR from '@salesforce/label/c.Back_Promotion_Error';
import BACK_PROMOTION_ENV_DETAIL from '@salesforce/label/c.Back_Promotion_Env_Detail';
import SELECTED_ENVIRONMENTS from '@salesforce/label/c.Selected_Environments';
import SELECTED_ENVIRONMENTS_HELPTEXT from '@salesforce/label/c.Selected_Env_Helptext';

import AUTOMATION_RULE_ACTIVE from '@salesforce/schema/Automation_Rule__c.Active__c';
import AUTOMATION_RULE_CONFIG_JSON from '@salesforce/schema/Automation_Rule__c.Config_Json__c';

export const label = {
    EDIT,
    SAVE,
    CANCEL,
    CONFIGURE_SCOPE,
    NO_SCOPE_DEFINED,
    NO_SCOPE_DEFINED_BODY,
    CLEAR_ALL,
    INSUFFICIENT_PERMISSION,
    BACK_PROMOTION_AUTOMATION_SCOPE,
    EXCLUDED_ENVIRONMENTS,
    INCLUDED_ENVIRONMENTS,
    EXCLUDED_ENVIRONMENTS_HELPTEXT,
    BACK_PROMOTION_FIELD_LABEL,
    BACK_PROMOTION_ERROR,
    BACK_PROMOTION_ENV_DETAIL,
    SELECTED_ENVIRONMENTS,
    SELECTED_ENVIRONMENTS_HELPTEXT
};

export const schema = {
    AUTOMATION_RULE_ACTIVE,
    AUTOMATION_RULE_CONFIG_JSON
};

export const fields = [AUTOMATION_RULE_ACTIVE];