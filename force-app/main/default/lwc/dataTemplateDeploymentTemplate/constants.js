import DATA_TEMPLATE from '@salesforce/label/c.Data_Template';
import SELECT_TEMPLATE from '@salesforce/label/c.Select_Template';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import NEW_TEMPLATE from '@salesforce/label/c.QickCreateDataTemplate';
import QUICK_CREATE_TEMPLATE_MESSAGE from '@salesforce/label/c.QuickCreateTemplateMessage';
import QUICK_CREATE_TEMPLATE_INFO from '@salesforce/label/c.ADD_Relation_Template_Warning';
import DUPLICATE_TEMPLATE_NAME from '@salesforce/label/c.DuplicateTemplateName';
import COMPLETE_THIS_FIELD from '@salesforce/label/c.CompleteThisField';
import NEW from '@salesforce/label/c.NEW';
import SUCCESS_MESSAGE from '@salesforce/label/c.TemplateCreationSuccessMessage';
import TEMPLATE_MANDATORY_MESSAGE from '@salesforce/label/c.TemplateRequiredError';

import DATA_TEMPLATE_OBJECT from '@salesforce/schema/Data_Template__c';
import NAME from '@salesforce/schema/Data_Template__c.Name';
import SCHEMA_CREDETIAL from '@salesforce/schema/Data_Template__c.Template_Source_Org__c';
import ACTIVE from '@salesforce/schema/Data_Template__c.Active__c';
import MAIN_OBJECT from '@salesforce/schema/Data_Template__c.Main_Object__c';

export const label = {
    DATA_TEMPLATE,
    SELECT_TEMPLATE,
    SAVE,
    CANCEL,
    NEW,
    NEW_TEMPLATE,
    QUICK_CREATE_TEMPLATE_MESSAGE,
    QUICK_CREATE_TEMPLATE_INFO,
    DUPLICATE_TEMPLATE_NAME,
    COMPLETE_THIS_FIELD,
    SUCCESS_MESSAGE,
    TEMPLATE_MANDATORY_MESSAGE
};

export const schema = {
    DATA_TEMPLATE_OBJECT,
    NAME,
    SCHEMA_CREDETIAL,
    ACTIVE,
    MAIN_OBJECT
};

export const SELECT_TEMPLATE_OPTION = {
    label: SELECT_TEMPLATE,
    value: null
};