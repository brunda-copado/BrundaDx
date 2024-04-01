import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import PASSED from '@salesforce/label/c.PASSED';
import FAILED from '@salesforce/label/c.FAILED';
import STATUS from '@salesforce/label/c.STATUS';
import SAVE_SUCCESS from '@salesforce/label/c.SAVE_SUCCESS';
import STEP_REFERENCE from '@salesforce/label/c.Step_Reference';
import ACTION_DESCRIPTION from '@salesforce/label/c.Action_Description';
import EXPECTED_RESULT from '@salesforce/label/c.Expected_Result';
import GUIDANCE_NOTES from '@salesforce/label/c.Guidance_Notes';
import ACTUAL_RESULT from '@salesforce/label/c.Actual_Result';
import MANUAL_TEST_EXECUTION_RESULTS from '@salesforce/label/c.Manual_Test_Execution_Results';
import TEST_EXECUTION_RESULT_MESSAGE from '@salesforce/label/c.Test_Execution_Result_Message';
import NO_MANUAL_TEST_SCRIPTS from '@salesforce/label/c.No_Manual_Test_Scripts';
import NO_MANUAL_TEST_SCRIPTS_BODY from '@salesforce/label/c.No_Manual_Test_Scripts_Body';
import ACTUAL_RESULT_MAXIMUM_LENGTH_MESSAGE from '@salesforce/label/c.Manual_Test_Actual_Result_Maximum_Length';
import EXECUTE_STEPS_VALIDATION_ERROR from '@salesforce/label/c.Manual_Tests_Execute_Step_Validation_Error';
import MANUAL_TEST_NOT_RUNNABLE_TITLE from '@salesforce/label/c.ManualTestNotRunnableTitle';
import MANUAL_TEST_NOT_RUNNABLE_DETAILS from '@salesforce/label/c.ManualTestNotRunnableDetails';

import TEST_SCRIPT from '@salesforce/schema/Test_Script__c';
import SCRIPT_TITLE from '@salesforce/schema/Test_Script__c.Test_Title__c';
import SCRIPT_STEP_ACTION_DESCRIPTION from '@salesforce/schema/Test_Script_Step__c.Action_Description__c';
import SCRIPT_STEP_EXPECTED_RESULT from '@salesforce/schema/Test_Script_Step__c.Expected_Result__c';
import SCRIPT_STEP_GUIDANCE_NOTES from '@salesforce/schema/Test_Script_Step__c.Guidance_notes__c';
import SCRIPT_STEP_ORDER from '@salesforce/schema/Test_Script_Step__c.Order__c';
import RUN_STEP_STATUS from '@salesforce/schema/Test_Run_Step__c.Status__c';
import RUN_STEP_ACTUAL_RESULT from '@salesforce/schema/Test_Run_Step__c.Actual_Result__c';
import RUN_STEP_SCRIPT_STEP from '@salesforce/schema/Test_Run_Step__c.Script_Step__c';
import SUITE_SCRIPT_ORDER from '@salesforce/schema/Test_Suite_Script__c.Order__c';

export const labels = {
    EDIT,
    SAVE,
    CANCEL,
    PASSED,
    FAILED,
    STATUS,
    SAVE_SUCCESS,
    ACTION_DESCRIPTION,
    EXPECTED_RESULT,
    GUIDANCE_NOTES,
    ACTUAL_RESULT,
    STEP_REFERENCE,
    NO_MANUAL_TEST_SCRIPTS,
    NO_MANUAL_TEST_SCRIPTS_BODY,
    TEST_EXECUTION_RESULT_MESSAGE,
    MANUAL_TEST_EXECUTION_RESULTS,
    ACTUAL_RESULT_MAXIMUM_LENGTH_MESSAGE,
    EXECUTE_STEPS_VALIDATION_ERROR,
    MANUAL_TEST_NOT_RUNNABLE_TITLE,
    MANUAL_TEST_NOT_RUNNABLE_DETAILS
};

export const schema = {
    TEST_SCRIPT,
    SCRIPT_TITLE,
    SCRIPT_STEP_ORDER,
    SCRIPT_STEP_EXPECTED_RESULT,
    SCRIPT_STEP_ACTION_DESCRIPTION,
    SCRIPT_STEP_GUIDANCE_NOTES,
    RUN_STEP_STATUS,
    RUN_STEP_ACTUAL_RESULT,
    RUN_STEP_SCRIPT_STEP,
    SUITE_SCRIPT_ORDER
};