import Id from '@salesforce/schema/ExtensionConfiguration__c.Id';
import Active from '@salesforce/schema/ExtensionConfiguration__c.Active__c';

import EXTENSION_DEACTIVATION_MESSAGE from '@salesforce/label/c.ExtensionDeactivationMessage';
import EXTENSION_DEACTIVATION_HEADER from '@salesforce/label/c.ExtensionDeactivationHeader';
import SUCCESS_MESSAGE from '@salesforce/label/c.ExtensionDeactivated';
import CANCEL from '@salesforce/label/c.Cancel';
import DEACTIVATE from '@salesforce/label/c.Deactivate';

export const schema = {
    Id,
    Active
};

export const label = {
    EXTENSION_DEACTIVATION_MESSAGE,
    EXTENSION_DEACTIVATION_HEADER,
    SUCCESS_MESSAGE,
    CANCEL,
    DEACTIVATE
};