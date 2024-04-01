import ICONS from '@salesforce/resourceUrl/ResultMonitorIconSet';

import JOB_EXECUTION_STATUS from '@salesforce/schema/JobExecution__c.Status__c';
import JOB_EXECUTION_CREATED_DATE from '@salesforce/schema/JobExecution__c.CreatedDate';
import JOB_EXECUTION_JOB_TEMPLATE from '@salesforce/schema/JobExecution__c.Template__c';
import JOB_TEMPLATE_NAME from '@salesforce/schema/JobTemplate__c.Name';
import JOB_STEP_RESULT from '@salesforce/schema/JobStep__c.Result__c';
import JOB_STEP_STATUS from '@salesforce/schema/JobStep__c.Status__c';

import TYPE from '@salesforce/label/c.TYPE';
import TEST from '@salesforce/label/c.StepTypeTest';
import RESULT from '@salesforce/label/c.Result';
import DETAILS from '@salesforce/label/c.DETAILS';
import SUCCESS from '@salesforce/label/c.SUCCESS';
import ERROR from '@salesforce/label/c.ERROR';
import INPROGRESS from '@salesforce/label/c.SprintWall_In_Progress';
import CANCELLATION from '@salesforce/label/c.Cancellation';
import PENDING from '@salesforce/label/c.PENDING';
import UPDATE_STEP_PROGRESS from '@salesforce/label/c.UpdateStepProgress';

export const schema = {
    JOB_EXECUTION_STATUS,
    JOB_EXECUTION_CREATED_DATE,
    JOB_EXECUTION_JOB_TEMPLATE,
    JOB_TEMPLATE_NAME,
    JOB_STEP_RESULT,
    JOB_STEP_STATUS
};

const TEST_ERROR_ICON = ICONS + '/ErrorTestStep.svg';
const TEST_SUCCESS_ICON = ICONS + '/SuccessTestStep.svg';
const TEST_IN_PROGRESS_ICON = ICONS + '/InProgressTestStep.svg';
const TEST_NOT_STARTED_ICON = ICONS + '/NotStartedTestStep.svg';

export const images = {
    TEST_ERROR_ICON,
    TEST_SUCCESS_ICON,
    TEST_IN_PROGRESS_ICON,
    TEST_NOT_STARTED_ICON
};

export const label = {
    TYPE,
    TEST,
    RESULT,
    DETAILS,
    SUCCESS,
    ERROR,
    INPROGRESS,
    CANCELLATION,
    PENDING,
    UPDATE_STEP_PROGRESS
};