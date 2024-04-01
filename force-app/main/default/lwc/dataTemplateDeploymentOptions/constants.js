import DATA_TEMPLATE from '@salesforce/schema/Data_Template__c'; // need to check if we have to use name space
import ATTACHMENT_OPTIONS from '@salesforce/schema/Data_Template__c.Attachment_Options__c';
import MATCH_OWNERS from '@salesforce/schema/Data_Template__c.Match_Owners__c';
import MATCH_RECORD_TYPES from '@salesforce/schema/Data_Template__c.Match_Record_Type__c';
import DATA_TEMPLATE_ACTIVE from '@salesforce/schema/Data_Template__c.Active__c';
import CONTINUE_ON_ERROR from '@salesforce/schema/Data_Template__c.Continue_on_Error__c';

import SELECT_ATTACHMENT_TYPE from '@salesforce/label/c.Select_Attachment_Type';
import FILES from '@salesforce/label/c.Files_Lightning';
import ATTACHMENT from '@salesforce/label/c.Attachments_Classic';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import EDIT from '@salesforce/label/c.EDIT';
import DEPLOYMENT_OPTIONS from '@salesforce/label/c.Deployment_Options';
import EDIT_DATA_TEMPLATE from '@salesforce/label/c.EditDataTemplate';
import DEACTIVATE from '@salesforce/label/c.Deactivate';
import EDIT_VALIDATION_MESSAGE from '@salesforce/label/c.DataTemplateEditValidationMsg';

export const label = {
    FILES,
    ATTACHMENT,
    CANCEL,
    SAVE,
    EDIT,
    SELECT_ATTACHMENT_TYPE,
    DEPLOYMENT_OPTIONS,
    EDIT_DATA_TEMPLATE,
    DEACTIVATE,
    EDIT_VALIDATION_MESSAGE
};

export const schema = { DATA_TEMPLATE };

export const FIELDS = {
    ATTACHMENT_OPTIONS,
    MATCH_OWNERS,
    MATCH_RECORD_TYPES,
    DATA_TEMPLATE_ACTIVE,
    CONTINUE_ON_ERROR
};

export const SELECT_ATTACHMENT_OPTIONS = [
    { label: label.FILES, value: 'files' },
    { label: label.ATTACHMENT, value: 'attachments' }
];