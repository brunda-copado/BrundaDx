import AUTOMATED_ACTION from '@salesforce/label/c.Automated_Action';
import CONFIGURE from '@salesforce/label/c.Configure';
import TRIGGER from '@salesforce/label/c.Trigger';
import EXECUTION from '@salesforce/label/c.Execution';
import POST_AUTOMATION from '@salesforce/label/c.POST_AUTOMATION';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import INSUFFICIENT_PERMISSION from '@salesforce/label/c.No_necessary_permission_for_automation_rule';
import CONTINUOUS_DELIVERY from '@salesforce/label/c.Continuous_Delivery';
import PROMOTION from '@salesforce/label/c.Automation_Connector_Promotion';
import BACK_PROMOTION from '@salesforce/label/c.Automation_Connector_Back_Promotion';
import CUSTOM_AUTOMATION_CONNECTOR from '@salesforce/label/c.Custom_Automation_Connector';
import EDIT_AUTOMATION from '@salesforce/label/c.Edit_Automation';
import EDIT_AUTOMATION_WARNING_ALERT from '@salesforce/label/c.Edit_Automation_Warning_Alert';
import EDIT_AUTOMATION_BODY_MESSAGE from '@salesforce/label/c.Edit_Automation_Body_Message';
import AUTOMATION_SCOPE_RESET from '@salesforce/label/c.AutomationScopeReset';
import EXECUTE_QUALITY_GATE from '@salesforce/label/c.Execute_Quality_Gate';
import QUALITY_GATE from '@salesforce/label/c.Quality_Gate';

import USER_STORY_OBJECT from '@salesforce/schema/User_Story__c';
import AUTOMATION_RULE_OBJECT from '@salesforce/schema/Automation_Rule__c';
import AUTOMATION_RULE_ACTIVE from '@salesforce/schema/Automation_Rule__c.Active__c';
import AUTOMATION_RULE_AUTOMATED_ACTION from '@salesforce/schema/Automation_Rule__c.Automated_Action__c';
import AUTOMATION_RULE_AUTOMATED_ACTION_CALLBACK from '@salesforce/schema/Automation_Rule__c.Automated_Action_Callback__c';
import AUTOMATION_RULE_AUTOMATION_CONNECTOR from '@salesforce/schema/Automation_Rule__c.Automation_Connector__c';
import AUTOMATION_RULE_CRON_EXPRESSION from '@salesforce/schema/Automation_Rule__c.Cron_Expression__c';
import AUTOMATION_RULE_CUSTOM_AUTOMATION_CONNECTOR from '@salesforce/schema/Automation_Rule__c.Custom_Automation_Connector__c';
import AUTOMATION_RULE_EXECUTION from '@salesforce/schema/Automation_Rule__c.Execution__c';
import AUTOMATION_RULE_SOURCE_ACTION from '@salesforce/schema/Automation_Rule__c.Source_Action__c';
import AUTOMATION_RULE_SOURCE_ACTION_STATUS from '@salesforce/schema/Automation_Rule__c.Source_Action_Status__c';
import AUTOMATION_RULE_FILTER_CRITERIA from '@salesforce/schema/Automation_Rule__c.Filter_Criteria__c';
import AUTOMATION_RULE_CONFIG_JSON from '@salesforce/schema/Automation_Rule__c.Config_Json__c';

export const labels = {
    INSUFFICIENT_PERMISSION,
    AUTOMATED_ACTION,
    CONFIGURE,
    TRIGGER,
    EXECUTION,
    POST_AUTOMATION,
    SAVE,
    CANCEL,
    CONTINUOUS_DELIVERY,
    PROMOTION,
    BACK_PROMOTION,
    CUSTOM_AUTOMATION_CONNECTOR,
    EDIT_AUTOMATION,
    EDIT_AUTOMATION_WARNING_ALERT,
    EDIT_AUTOMATION_BODY_MESSAGE,
    AUTOMATION_SCOPE_RESET,
    EXECUTE_QUALITY_GATE,
    QUALITY_GATE
};

export const schema = {
    USER_STORY_OBJECT,
    AUTOMATION_RULE_OBJECT,
    AUTOMATION_RULE_ACTIVE,
    AUTOMATION_RULE_AUTOMATED_ACTION,
    AUTOMATION_RULE_AUTOMATED_ACTION_CALLBACK,
    AUTOMATION_RULE_AUTOMATION_CONNECTOR,
    AUTOMATION_RULE_CRON_EXPRESSION,
    AUTOMATION_RULE_CUSTOM_AUTOMATION_CONNECTOR,
    AUTOMATION_RULE_EXECUTION,
    AUTOMATION_RULE_SOURCE_ACTION,
    AUTOMATION_RULE_SOURCE_ACTION_STATUS,
    AUTOMATION_RULE_FILTER_CRITERIA,
    AUTOMATION_RULE_CONFIG_JSON
};

export const fields = [
    AUTOMATION_RULE_ACTIVE,
    AUTOMATION_RULE_AUTOMATED_ACTION,
    AUTOMATION_RULE_AUTOMATED_ACTION_CALLBACK,
    AUTOMATION_RULE_AUTOMATION_CONNECTOR,
    AUTOMATION_RULE_CRON_EXPRESSION,
    AUTOMATION_RULE_CUSTOM_AUTOMATION_CONNECTOR,
    AUTOMATION_RULE_EXECUTION,
    AUTOMATION_RULE_SOURCE_ACTION,
    AUTOMATION_RULE_SOURCE_ACTION_STATUS,
    AUTOMATION_RULE_FILTER_CRITERIA,
    AUTOMATION_RULE_CONFIG_JSON
];

const CUSTOM = 'Custom';
const SCHEDULED = 'Scheduled';
const IMMEDIATE = 'Immediate';
const BACK_PROMOTION_CONNECTOR = 'ACPromotionDeploymentToBackPromotion';
const PROMOTION_CONNECTOR = 'ACPromotionDeploymentToPromotion';
const SUBMIT_US_CONNECTOR = 'ACSubmitUserStoriesToPromotionDeployment';

export const constants = {
    CUSTOM,
    SCHEDULED,
    IMMEDIATE,
    BACK_PROMOTION_CONNECTOR,
    PROMOTION_CONNECTOR,
    SUBMIT_US_CONNECTOR
};