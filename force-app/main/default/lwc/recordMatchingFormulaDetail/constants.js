import FIELD_1 from '@salesforce/label/c.RecordMatchingFormulaField1';
import FIELD_2 from '@salesforce/label/c.RecordMatchingFormulaField2';
import FIELD_3 from '@salesforce/label/c.RecordMatchingFormulaField3';
import OBJECT_LABEL from '@salesforce/label/c.ObjectLabel';
import EDIT from '@salesforce/label/c.EDIT';
import RELATED_FIELD from '@salesforce/label/c.RelatedField';

import RECORD_MATCHING_FORMULA from '@salesforce/schema/Record_Matching_Formula__c';
import OBJECT from '@salesforce/schema/Record_Matching_Formula__c.Object__c';
import HASH_FORMULA from '@salesforce/schema/Record_Matching_Formula__c.Hash_Formula__c';
import FIELD1 from '@salesforce/schema/Record_Matching_Formula__c.Field_1__c';
import FIELD2 from '@salesforce/schema/Record_Matching_Formula__c.Field_2__c';
import FIELD3 from '@salesforce/schema/Record_Matching_Formula__c.Field_3__c';
import FIELD_LABELS from '@salesforce/schema/Record_Matching_Formula__c.Field_Labels__c';

export const labels = {
    FIELD_1,
    FIELD_2,
    FIELD_3,
    OBJECT_LABEL,
    EDIT,
    RELATED_FIELD
}

export const schema = {
    RECORD_MATCHING_FORMULA,
    OBJECT,
    HASH_FORMULA,
    FIELD1,
    FIELD2,
    FIELD3,
    FIELD_LABELS
}