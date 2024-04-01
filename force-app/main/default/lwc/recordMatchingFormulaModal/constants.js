//Custom labels
import CONFIGURE_RECORDMATCHING_FORMULA from '@salesforce/label/c.Configure_Record_Matching_Formula';
import RECORD_MATCHING_FORMULA_DESCRIPTION from '@salesforce/label/c.ConfigureRecordMatchingFormulaDescription';
import RELATED_FIELD from '@salesforce/label/c.RelatedField';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import DELETE from '@salesforce/label/c.DELETE';
import OBJECT_FIELD_HELP_TEXT from '@salesforce/label/c.Object_Field_Help_Text';
import COMPLETE_THIS_FIELD from '@salesforce/label/c.CompleteThisField';
import SELECT_FIELD from '@salesforce/label/c.SelectField';
import FIELD_1 from '@salesforce/label/c.RecordMatchingFormulaField1';
import FIELD_2 from '@salesforce/label/c.RecordMatchingFormulaField2';
import FIELD_3 from '@salesforce/label/c.RecordMatchingFormulaField3';
import OBJECT_LABEL from '@salesforce/label/c.ObjectLabel';
import CREDENTIAL_ACCESS_MESSAGE from '@salesforce/label/c.SchemaCredentialAccessMessage';
import RECORD_MATCHING_AUTH_ERROR from '@salesforce/label/c.RecordMatchingAuthenticationError';
import OBJECT_IN_USE from '@salesforce/label/c.ObjectInUseErrorMessage';
import OBJECT_HELP_TEXT from '@salesforce/label/c.Object_Field_Help_Text';
import UPDATE_SUCCESSFUL from '@salesforce/label/c.FormulaUpdateSuccessMessage';
import SEARCH_OBJECT from '@salesforce/label/c.SearchObject';
import FORMULA_EDIT_INFO from '@salesforce/label/c.FormulaEditInfoMessage';
import RELATED_FIELD_HELP_TEXT from '@salesforce/label/c.RelatedFieldHelpText';

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
import FIELD_LABELS from '@salesforce/schema/Record_Matching_Formula__c.Field_Labels__c';

export const labels = {
    CONFIGURE_RECORDMATCHING_FORMULA,
    RECORD_MATCHING_FORMULA_DESCRIPTION,
    RELATED_FIELD,
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
    OBJECT_IN_USE,
    OBJECT_HELP_TEXT,
    UPDATE_SUCCESSFUL,
    OBJECT_LABEL,
    SEARCH_OBJECT,
    FORMULA_EDIT_INFO,
    RELATED_FIELD_HELP_TEXT
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
    FIELD_LABELS
};