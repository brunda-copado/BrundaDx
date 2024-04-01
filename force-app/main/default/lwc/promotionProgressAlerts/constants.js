import PROMOTION_PROGRESS_ALERT from '@salesforce/label/c.Promotion_Progress_Alert_Failed_Quality_Checks';
import DEPLOYMENT_PROGRESS_ALERT from '@salesforce/label/c.Deployment_Progress_Alert_Failed_Quality_Checks';
import JOB_EXECUTION_STATUS_FIELD from '@salesforce/schema/JobExecution__c.Status__c';

const INFO = 'info';
const WARNING = 'warning';
const SUCCESS = 'success';
const ERROR = 'error';
const ADD = 'add';
const REMOVE = 'remove';

const PROMOTION_ALERTS = 'promotionProgressAlerts';

export const label = {
    PROMOTION_PROGRESS_ALERT,
    DEPLOYMENT_PROGRESS_ALERT
};

export const schema = {
    JOB_EXECUTION_STATUS_FIELD
};

export const messageParams = {
    INFO,
    WARNING,
    SUCCESS,
    ERROR,
    ADD,
    REMOVE
};

export const jobStatus = {
    SUCCESSFUL: 'Successful',
    ERROR: 'Error',
    IN_PROGRESS: 'In Progress',
    NOT_STARTED: 'Not Started'
};

export const communicationName = {
    PROMOTION_ALERTS
};