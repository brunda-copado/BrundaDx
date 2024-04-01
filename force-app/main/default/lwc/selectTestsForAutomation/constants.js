import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import CLOSE from '@salesforce/label/c.CLOSE';
import CLEAR_ALL from '@salesforce/label/c.Clear_All';
import ERROR from '@salesforce/label/c.ERROR';
import TEST from '@salesforce/label/c.TEST';
import FIELD_LABEL_HELP_TEXT from '@salesforce/label/c.Field_Label_Help_Text';
import ERROR_SEARCHING_RECORDS from '@salesforce/label/c.Error_Searching_Records';
import RECORDS_UPDATED_SUCCESSFULLY from '@salesforce/label/c.Records_Updated_Successfully';
import SELECT_TESTS from '@salesforce/label/c.Select_Tests';
import SELECT_TESTS_VALIDATION_ERROR from '@salesforce/label/c.Select_CRT_Tests_Validation_Error';
import SELECT_ACTIVE_COPADO_ROBOTIC_TESTING_TESTS from '@salesforce/label/c.Select_Active_Copado_Robotic_Testing_Tests';
import SELECT_ACTIVE_COPADO_ROBOTIC_TESTING_TESTS_HELPTEXT from '@salesforce/label/c.Select_Active_Copado_Robotic_Testing_Tests_Helptext';

import TEST_OBJECT from '@salesforce/schema/Test__c';
import TEST_TOOL_FIELD from '@salesforce/schema/Test__c.Test_Tool__c';
import TEST_TOOL_CONFIGURATION_FIELD from '@salesforce/schema/Test__c.ExtensionConfiguration__c';
import QUALITY_GATE_OBJECT from '@salesforce/schema/Quality_Gate__c';
import QUALITY_GATE_ID_FIELD from '@salesforce/schema/Quality_Gate__c.Id';
import QUALITY_GATE_DATA_JSON_FIELD from '@salesforce/schema/Quality_Gate__c.DataJSON__c';

export const label = {
    EDIT,
    SAVE,
    CANCEL,
    CLOSE,
    TEST,
    CLEAR_ALL,
    FIELD_LABEL_HELP_TEXT,
    ERROR_SEARCHING_RECORDS,
    RECORDS_UPDATED_SUCCESSFULLY,
    ERROR,
    SELECT_TESTS,
    SELECT_TESTS_VALIDATION_ERROR,
    SELECT_ACTIVE_COPADO_ROBOTIC_TESTING_TESTS,
    SELECT_ACTIVE_COPADO_ROBOTIC_TESTING_TESTS_HELPTEXT
};

export const schema = {
    TEST_OBJECT,
    QUALITY_GATE_OBJECT,
    QUALITY_GATE_ID_FIELD,
    QUALITY_GATE_DATA_JSON_FIELD,
    TEST_TOOL_FIELD,
    TEST_TOOL_CONFIGURATION_FIELD
};

export const fields = [QUALITY_GATE_DATA_JSON_FIELD];
export const copadoCRTExtensionTool = 'Copado Robotic Testing';