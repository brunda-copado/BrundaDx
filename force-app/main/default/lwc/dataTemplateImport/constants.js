import DATA_TEMPLATE from '@salesforce/schema/Data_Template__c';
import SOURCE_ORG_FIELD from '@salesforce/schema/Data_Template__c.Template_Source_Org__c';
import ACTIVE from '@salesforce/schema/Data_Template__c.Active__c';
import MAIN_OBJECT from '@salesforce/schema/Data_Template__c.Main_Object__c';
import MAX_RECORD_LIMIT from '@salesforce/schema/Data_Template__c.Max_Record_Limit__c';
import DESCRIPTION from '@salesforce/schema/Data_Template__c.Description__c';
import FILTER_LOGIC from '@salesforce/schema/Data_Template__c.Filter_Logic__c';
import ATTACHMENT_OPTIONS from '@salesforce/schema/Data_Template__c.Attachment_Options__c';
import BATCH_SIZE from '@salesforce/schema/Data_Template__c.Batch_Size__c';
import MATCH_OWNERS from '@salesforce/schema/Data_Template__c.Match_Owners__c';
import MATCH_RECORDTYPE from '@salesforce/schema/Data_Template__c.Match_Record_Type__c';
import CONTINUE_ON_ERROR from '@salesforce/schema/Data_Template__c.Continue_on_Error__c';
import NAME from '@salesforce/schema/Data_Template__c.Name';




import CANCEL from '@salesforce/label/c.Cancel';
import BACK from '@salesforce/label/c.BACK';
import IMPORT_TEMPLATE from '@salesforce/label/c.ImportTemplateHeading';
import RELATED_DATA_TEMPLATES from '@salesforce/label/c.Related_Data_Templates';
import OBJECT_FOUND from '@salesforce/label/c.Object_Is_Found';
import OBJECT_NOT_FOUND from '@salesforce/label/c.Object_Is_Not_Found';
import DUPLICATE_TEMPLATE_NAME from '@salesforce/label/c.Duplicate_Template_Name_Import';
import ALL_TEMPLATES_VALID_MESSAGE from '@salesforce/label/c.AllTemplatesValidMessage';
import ALL_TEMPLATES_INVALID_MESSAGE from '@salesforce/label/c.AllTemplatesInvalidMessage';
import SOME_TEMPLATES_INVALID_MESSAGE from '@salesforce/label/c.SomeTemplatesInValidMessage';
import TEMPLATE_VALIDATION_MESSAGE from '@salesforce/label/c.TemplateValidationMessage';
import VALIDATION_ERRORS from '@salesforce/label/c.ValidationErrors';
import TEMPLATE_CREATE from '@salesforce/label/c.TemplateCreate';
import VALIDATE_TEMPLATES from '@salesforce/label/c.ValidateTemplates';
import ORG_NOT_AUTHENTICATED from '@salesforce/label/c.OrgNotAuthenticated';
import CLOSE_AND_RETURN from '@salesforce/label/c.CloseAndReturn';
import FINAL_MESSAGE from '@salesforce/label/c.FinalMessage';
import VALIDATED from '@salesforce/label/c.Validated';
import CREATED from '@salesforce/label/c.TemplatesCreated';

export const label = {
    BACK,
    IMPORT_TEMPLATE,
    CANCEL,
    RELATED_DATA_TEMPLATES,
    OBJECT_FOUND,
    OBJECT_NOT_FOUND,
    DUPLICATE_TEMPLATE_NAME,
    ALL_TEMPLATES_VALID_MESSAGE,
    ALL_TEMPLATES_INVALID_MESSAGE,
    SOME_TEMPLATES_INVALID_MESSAGE,
    TEMPLATE_VALIDATION_MESSAGE,
    VALIDATION_ERRORS,
    TEMPLATE_CREATE,
    VALIDATE_TEMPLATES,
    ORG_NOT_AUTHENTICATED,
    CLOSE_AND_RETURN,
    FINAL_MESSAGE,
    VALIDATED,
    CREATED
};



export const schema = {
    DATA_TEMPLATE,
    SOURCE_ORG_FIELD,
    ACTIVE,
    MAIN_OBJECT,
    MAX_RECORD_LIMIT,
    DESCRIPTION,
    FILTER_LOGIC,
    ATTACHMENT_OPTIONS,
    BATCH_SIZE,
    MATCH_OWNERS,
    MATCH_RECORDTYPE,
    CONTINUE_ON_ERROR,
    NAME
};