import QUALITY_CHECKS from '@salesforce/label/c.Quality_Checks';
import LOADING from '@salesforce/label/c.LOADING';

import ICONS from '@salesforce/resourceUrl/ResultMonitorIconSet';

import JOB_EXECUTION_STATUS from '@salesforce/schema/JobExecution__c.Status__c';
import JOB_EXECUTION_LAST_MODIFIED_DATE from '@salesforce/schema/JobExecution__c.LastModifiedDate';

export const schema = {
    JOB_EXECUTION_STATUS,
    JOB_EXECUTION_LAST_MODIFIED_DATE
};

export const label = {
    QUALITY_CHECKS,
    LOADING
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

export const statuses = {
    SUCCESSFUL: 'Successful',
    ERROR: 'Error',
    IN_PROGRESS: 'In Progress',
    NOT_STARTED: 'Not Started'
};