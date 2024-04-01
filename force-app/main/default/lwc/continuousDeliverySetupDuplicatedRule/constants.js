import Setup_Continuous_Delivery from '@salesforce/label/c.Setup_Continuous_Delivery';
import ContinuousDeliveryDuplicatedRuleWarning from '@salesforce/label/c.ContinuousDeliveryDuplicatedRuleWarning';
import ContinuousDeliveryDuplicatedRuleError from '@salesforce/label/c.ContinuousDeliveryDuplicatedRuleError';
import Back from '@salesforce/label/c.BACK';
import Cancel from '@salesforce/label/c.Cancel';

import AUTOMATION_RULE_OBJECT from '@salesforce/schema/Automation_Rule__c';
import AUTOMATION_RULE_NAME from '@salesforce/schema/Automation_Rule__c.Name';
import AUTOMATION_RULE_SOURCE_ACTION from '@salesforce/schema/Automation_Rule__c.Source_Action__c';
import AUTOMATION_RULE_AUTOMATED_ACTION from '@salesforce/schema/Automation_Rule__c.Automated_Action__c';

export const label = {
    Setup_Continuous_Delivery,
    ContinuousDeliveryDuplicatedRuleWarning,
    ContinuousDeliveryDuplicatedRuleError,
    Back,
    Cancel
};

export const schema = {
    AUTOMATION_RULE_OBJECT,
    AUTOMATION_RULE_NAME,
    AUTOMATION_RULE_SOURCE_ACTION,
    AUTOMATION_RULE_AUTOMATED_ACTION
};