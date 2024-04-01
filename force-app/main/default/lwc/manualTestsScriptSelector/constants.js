import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import TEST_SCRIPT_HEADING from '@salesforce/label/c.Test_Script';
import TEST_REFERENCE from '@salesforce/label/c.Test_Reference';
import TEST_PREREQUISITES from '@salesforce/label/c.Test_Prerequisites';
import TEST_TITLE from '@salesforce/label/c.Test_Title';
import TEST_EXPECTED_RESULT from '@salesforce/label/c.Test_Expected_Result';
import TEST_SCRIPT_RISK from '@salesforce/label/c.Test_Script_Risk';
import STEPS from '@salesforce/label/c.Steps';
import STEP_REFERENCE from '@salesforce/label/c.Step_Reference';
import ACTION_DESCRIPTION from '@salesforce/label/c.Action_Description';
import EXPECTED_RESULT from '@salesforce/label/c.Expected_Result';
import GUIDANCE_NOTES from '@salesforce/label/c.Guidance_Notes';
import NOT_SELECTED_TEST_SCRIPTS from '@salesforce/label/c.Not_Selected_Test_Scripts';
import SELECT_SCRIPTS from '@salesforce/label/c.Select_Test_Scripts';
import CLOSE from '@salesforce/label/c.CLOSE';
import TEST_SCRIPTS_DETAILS from '@salesforce/label/c.Test_Scripts_Details';
import TEST_SCRIPTS_SELECTION from '@salesforce/label/c.Test_Scripts_Selection';
import WARNING_ORDER from '@salesforce/label/c.Warning_Order_Test_Scripts';
import PROJECT from '@salesforce/label/c.Project';
import ADD_TEST_SCRIPT from '@salesforce/label/c.Add_Test_Script';
import SELECT from '@salesforce/label/c.SELECT';
import DELETE from '@salesforce/label/c.DELETE';
import COMPLETE_ALL_FIELDS from '@salesforce/label/c.Complete_All_Fields';
import DUPLICATE_SCRIPTS from '@salesforce/label/c.Duplicate_Scripts_Message';
import ERROR_SEARCHING from '@salesforce/label/c.Error_Searching_Records';
import SCRIPT_SAVED from '@salesforce/label/c.Script_Save_Successful';
import SCRIPT_SAVE_ERROR from '@salesforce/label/c.Error_in_saving_scripts';
import NO_STEPS_TO_DISPLAY from '@salesforce/label/c.NoStepsToDisplay';
import MANUAL_TESTS_SCRIPTS_TITLE from '@salesforce/label/c.ManualTestsScriptsTitle';

import TEST_SCRIPT from '@salesforce/schema/Test_Script__c';
import SCRIPT_TITLE from '@salesforce/schema/Test_Script__c.Test_Title__c';
import SCRIPT_PREREQUISITES from '@salesforce/schema/Test_Script__c.Prerequisites__c';
import SCRIPT_EXPECTED_RESULT from '@salesforce/schema/Test_Script__c.Expected_Result__c';
import SCRIPT_RISK from '@salesforce/schema/Test_Script__c.Risk__c';
import SCRIPT_PROJECT from '@salesforce/schema/Test_Script__c.Project__c';
import SCRIPT_STEP_ACTION_DESCRIPTION from '@salesforce/schema/Test_Script_Step__c.Action_Description__c';
import SCRIPT_STEP_EXPECTED_RESULT from '@salesforce/schema/Test_Script_Step__c.Expected_Result__c';
import SCRIPT_STEP_GUIDANCE_NOTES from '@salesforce/schema/Test_Script_Step__c.Guidance_notes__c';
import SCRIPT_STEP_ORDER from '@salesforce/schema/Test_Script_Step__c.Order__c';
import SUITE_SCRIPT_ORDER from '@salesforce/schema/Test_Suite_Script__c.Order__c';

export const labels = {
    EDIT,
    SAVE,
    CANCEL,
    TEST_SCRIPT_HEADING,
    TEST_REFERENCE,
    TEST_PREREQUISITES,
    TEST_TITLE,
    TEST_EXPECTED_RESULT,
    TEST_SCRIPT_RISK,
    STEPS,
    STEP_REFERENCE,
    ACTION_DESCRIPTION,
    EXPECTED_RESULT,
    GUIDANCE_NOTES,
    NOT_SELECTED_TEST_SCRIPTS,
    SELECT_SCRIPTS,
    CLOSE,
    TEST_SCRIPTS_DETAILS,
    TEST_SCRIPTS_SELECTION,
    WARNING_ORDER,
    PROJECT,
    ADD_TEST_SCRIPT,
    SELECT,
    DELETE,
    COMPLETE_ALL_FIELDS,
    DUPLICATE_SCRIPTS,
    ERROR_SEARCHING,
    SCRIPT_SAVED,
    SCRIPT_SAVE_ERROR,
    NO_STEPS_TO_DISPLAY,
    MANUAL_TESTS_SCRIPTS_TITLE
};

export const schema = {
    TEST_SCRIPT,
    SCRIPT_TITLE,
    SCRIPT_PREREQUISITES,
    SCRIPT_EXPECTED_RESULT,
    SCRIPT_STEP_EXPECTED_RESULT,
    SCRIPT_RISK,
    SCRIPT_PROJECT,
    SCRIPT_STEP_ACTION_DESCRIPTION,
    SCRIPT_STEP_GUIDANCE_NOTES,
    SCRIPT_STEP_ORDER,
    SUITE_SCRIPT_ORDER
};