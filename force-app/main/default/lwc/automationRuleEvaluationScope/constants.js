import TRIGGER_SCOPE from '@salesforce/label/c.Trigger_Scope';
import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import STAGES from '@salesforce/label/c.Stages';
import EXCLUDED from '@salesforce/label/c.Excluded';
import SELECTED from '@salesforce/label/c.SELECTED';
import ENVIRONMENTS from '@salesforce/label/c.Environments';
import SCOPE_MODE from '@salesforce/label/c.Scope_Mode';
import SCOPE_MODE_HELPTEXT from '@salesforce/label/c.Scope_Mode_Helptext';
import MAXIMUM_SELECTED_STAGES from '@salesforce/label/c.Maximum_Selected_Stages';
import MAXIMUM_EXCLUDED_ENVIRONMENTS from '@salesforce/label/c.Maximum_Excluded_Environments';
import MAXIMUM_SELECTED_ENVIRONMENTS from '@salesforce/label/c.Maximum_Selected_Environments';
import CONFIGURE_SCOPE from '@salesforce/label/c.Configure_Scope';
import NO_SCOPE_DEFINED_BODY from '@salesforce/label/c.No_Scope_Defined_Body';
import NO_SCOPE_DEFINED from '@salesforce/label/c.No_Scope_Defined';
import CLEAR_ALL from '@salesforce/label/c.Clear_All';
import INSUFFICIENT_PERMISSION from '@salesforce/label/c.No_necessary_permission_for_automation_rule';
import TRIGGER_SCOPE_LABEL from '@salesforce/label/c.Trigger_Scope_Label';
import SCOPE_CANNNOT_BE_CONFIGURED from '@salesforce/label/c.Scope_Cannot_Be_Configured';
import SCOPE_ERROR_BODY from '@salesforce/label/c.Configure_Scope_Error_Body';
import CLOSE from '@salesforce/label/c.CLOSE';

import AUTOMATION_RULE_OBJECT from '@salesforce/schema/Automation_Rule__c';
import AUTOMATION_RULE_STAGE from '@salesforce/schema/Automation_Rule__c.Stage__c';
import AUTOMATION_RULE_ENVIRONMENT from '@salesforce/schema/Automation_Rule__c.Environment__c';
import AUTOMATION_RULE_EXCLUDED_ENVIRONMENTS from '@salesforce/schema/Automation_Rule__c.Excluded_Environments__c';
import AUTOMATION_RULE_ACTIVE from '@salesforce/schema/Automation_Rule__c.Active__c';
import AUTOMATION_RULE_SOURCE_ACTION from '@salesforce/schema/Automation_Rule__c.Source_Action__c';
import AUTOMATION_RULE_SOURCE_ACTION_STATUS from '@salesforce/schema/Automation_Rule__c.Source_Action_Status__c';
import AUTOMATION_RULE_AUTOMATION_CONNECTOR from '@salesforce/schema/Automation_Rule__c.Automation_Connector__c';

import STAGE_DISPLAY_NAME from '@salesforce/schema/Stage__c.Display_Name__c';

export const label = {
    TRIGGER_SCOPE,
    TRIGGER_SCOPE_LABEL,
    EDIT,
    SAVE,
    CANCEL,
    CLOSE,
    STAGES,
    EXCLUDED,
    SELECTED,
    ENVIRONMENTS,
    SCOPE_MODE,
    SCOPE_MODE_HELPTEXT,
    MAXIMUM_SELECTED_STAGES,
    MAXIMUM_EXCLUDED_ENVIRONMENTS,
    MAXIMUM_SELECTED_ENVIRONMENTS,
    NO_SCOPE_DEFINED,
    NO_SCOPE_DEFINED_BODY,
    CONFIGURE_SCOPE,
    CLEAR_ALL,
    INSUFFICIENT_PERMISSION,
    SCOPE_CANNNOT_BE_CONFIGURED,
    SCOPE_ERROR_BODY
};

export const schema = {
    AUTOMATION_RULE_OBJECT,
    AUTOMATION_RULE_STAGE,
    AUTOMATION_RULE_ENVIRONMENT,
    AUTOMATION_RULE_EXCLUDED_ENVIRONMENTS,
    AUTOMATION_RULE_ACTIVE,
    AUTOMATION_RULE_SOURCE_ACTION,
    AUTOMATION_RULE_SOURCE_ACTION_STATUS,
    AUTOMATION_RULE_AUTOMATION_CONNECTOR,
    STAGE_DISPLAY_NAME
};

export const fields = [
    AUTOMATION_RULE_ACTIVE,
    AUTOMATION_RULE_SOURCE_ACTION,
    AUTOMATION_RULE_SOURCE_ACTION_STATUS,
    AUTOMATION_RULE_AUTOMATION_CONNECTOR
];

export const ENVIRONMENTS_VALUE = 'Environments';
export const STAGES_VALUE = 'Stages';

export const scopeModeOptions = [
    { label: label.STAGES, value: STAGES_VALUE },
    { label: label.ENVIRONMENTS, value: ENVIRONMENTS_VALUE }
];

export const MAX_SELECTED = 13;