import ACTIVATE from '@salesforce/label/c.ACTIVATE';
import CANCEL from '@salesforce/label/c.Cancel';
import HEADER from '@salesforce/label/c.ActivatingAutomationHeaderMessage';
import BODY from '@salesforce/label/c.ActivatingAutomationBodyMessage';
import BANNER_ERROR from '@salesforce/label/c.ActivatingAutomationHeaderErrorMessage';
import TOAST_SUCCESS from '@salesforce/label/c.ActivatingAutomationSuccessToast';
import DUPLICATED_ERROR from '@salesforce/label/c.ActivatingAutomationDuplicatedError';

import AUTOMATION_RULE_OBJECT from '@salesforce/schema/Automation_Rule__c';
import AUTOMATION_RULE_NAME from '@salesforce/schema/Automation_Rule__c.Name';
import AUTOMATION_RULE_SOURCE_ACTION from '@salesforce/schema/Automation_Rule__c.Source_Action__c';
import AUTOMATION_RULE_AUTOMATED_ACTION from '@salesforce/schema/Automation_Rule__c.Automated_Action__c';

export const labels = {
    ACTIVATE,
    CANCEL,
    HEADER,
    BODY,
    BANNER_ERROR,
    TOAST_SUCCESS,
    DUPLICATED_ERROR
};

export const schema = {
    AUTOMATION_RULE_OBJECT,
    AUTOMATION_RULE_NAME,
    AUTOMATION_RULE_SOURCE_ACTION,
    AUTOMATION_RULE_AUTOMATED_ACTION
};