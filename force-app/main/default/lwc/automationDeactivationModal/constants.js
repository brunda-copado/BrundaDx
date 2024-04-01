import DEACTIVATE from '@salesforce/label/c.Deactivate';
import CANCEL from '@salesforce/label/c.Cancel';
import HEADER from '@salesforce/label/c.DeactivatingAutomationHeaderMessage';
import BODY from '@salesforce/label/c.DeactivatingAutomationBodyMessage';
import BANNER_ERROR from '@salesforce/label/c.DeactivatingAutomationHeaderErrorMessage';
import TOAST_SUCCESS from '@salesforce/label/c.DeactivatingAutomationSuccessToast';

import AUTOMATION_RULE_NAME from '@salesforce/schema/Automation_Rule__c.Name';

export const labels = {
    DEACTIVATE,
    CANCEL,
    HEADER,
    BODY,
    BANNER_ERROR,
    TOAST_SUCCESS
};

export const schema = {
    AUTOMATION_RULE_NAME
};