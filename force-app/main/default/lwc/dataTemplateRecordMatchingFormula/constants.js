//Custom labels
import CONFIGURE_RECORDMATCHING_FORMULA from '@salesforce/label/c.Configure_Record_Matching_Formula';
import RECORD_MATCHING_FORMULA_DESCRIPTION from '@salesforce/label/c.ConfigureRecordMatchingFormulaDescription';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import DELETE from '@salesforce/label/c.DELETE';
import OBJECT_FIELD_HELP_TEXT from '@salesforce/label/c.Object_Field_Help_Text';
import COMPLETE_THIS_FIELD from '@salesforce/label/c.CompleteThisField';
import SELECT_FIELD from '@salesforce/label/c.SelectField';
import FIELD_1 from '@salesforce/label/c.RecordMatchingFormulaField1';
import FIELD_2 from '@salesforce/label/c.RecordMatchingFormulaField2';
import FIELD_3 from '@salesforce/label/c.RecordMatchingFormulaField3';
import CREDENTIAL_ACCESS_MESSAGE from '@salesforce/label/c.SchemaCredentialAccessMessage';
import UNIQUE_INFO from '@salesforce/label/c.FormulaEditInfoMessage';


// Schema details from the record matching formula SelectField
import RECORD_MATCHING_FORMULA from '@salesforce/schema/Record_Matching_Formula__c';
import RECORD_ID from '@salesforce/schema/Record_Matching_Formula__c.Id';
import RECORD_NAME from '@salesforce/schema/Record_Matching_Formula__c.Name';
import CONFIGURATION_SOURCE_ORG from '@salesforce/schema/Record_Matching_Formula__c.Configuration_Source_Org__c';
import OBJECT from '@salesforce/schema/Record_Matching_Formula__c.Object__c';
import HASH_FORMULA from '@salesforce/schema/Record_Matching_Formula__c.Hash_Formula__c';
import FIELD1 from '@salesforce/schema/Record_Matching_Formula__c.Field_1__c';
import FIELD2 from '@salesforce/schema/Record_Matching_Formula__c.Field_2__c';
import FIELD3 from '@salesforce/schema/Record_Matching_Formula__c.Field_3__c';
import RELATED_FIELD_HELP_TEXT from '@salesforce/label/c.RelatedFieldHelpText';
import RELATED_FIELD from '@salesforce/label/c.RelatedField';

// Schema details for data template
import SCHEMA_CREDENTIAL from '@salesforce/schema/Data_Template__c.Template_Source_Org__c';
import TEMPLATE_MAIN_OBJECT from '@salesforce/schema/Data_Template__c.Main_Object__c';
import RECORD_MATCHING_AUTH_ERROR from '@salesforce/label/c.RecordMatchingAuthenticationError';
import FIELD_LABELS from '@salesforce/schema/Record_Matching_Formula__c.Field_Labels__c';

export const labels = {
    CONFIGURE_RECORDMATCHING_FORMULA,
    RECORD_MATCHING_FORMULA_DESCRIPTION,
    OBJECT_FIELD_HELP_TEXT,
    CANCEL,
    SAVE,
    DELETE,
    COMPLETE_THIS_FIELD,
    SELECT_FIELD,
    FIELD_1,
    FIELD_2,
    FIELD_3,
    CREDENTIAL_ACCESS_MESSAGE,
    RECORD_MATCHING_AUTH_ERROR,
    UNIQUE_INFO,
    RELATED_FIELD_HELP_TEXT,
    RELATED_FIELD
};

export const schema = {
    RECORD_MATCHING_FORMULA,
    RECORD_ID,
    RECORD_NAME,
    CONFIGURATION_SOURCE_ORG,
    OBJECT,
    HASH_FORMULA,
    FIELD1,
    FIELD2,
    FIELD3,
    SCHEMA_CREDENTIAL,
    TEMPLATE_MAIN_OBJECT,
    FIELD_LABELS
};