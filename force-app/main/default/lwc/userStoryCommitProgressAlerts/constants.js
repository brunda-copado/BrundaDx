import USER_STORY_COMMIT_IN_PROGRESS_ALERT from '@salesforce/label/c.USER_STORY_COMMIT_IN_PROGRESS_ALERT';
import USER_STORY_COMMIT_FAILED_ALERT from '@salesforce/label/c.USER_STORY_COMMIT_FAILED_ALERT';
import USER_STORY_COMMIT_SUCCESS_ALERT from '@salesforce/label/c.USER_STORY_COMMIT_SUCCESS_ALERT';
import USER_STORY_COMMIT_SUCCESS_ALERT_FAILED_QUALITY_CHECKS from '@salesforce/label/c.USER_STORY_COMMIT_SUCCESS_ALERT_FAILED_QUALITY_CHECKS';
import USER_STORY_COMMIT_NO_CHANGES_ALERT from '@salesforce/label/c.COMMIT_NO_CHANGES';
import COMMIT_NO_CHANGES_FAILED_QUALITY_CHECKS from '@salesforce/label/c.COMMIT_NO_CHANGES_FAILED_QUALITY_CHECKS';
import PROMOTION_IN_PROGRESS_ALERT from '@salesforce/label/c.PROMOTION_IN_PROGRESS_ALERT';

import JOB_EXECUTION_STATUS_FIELD from '@salesforce/schema/JobExecution__c.Status__c';
import JOB_EXECUTION_USER_STORY_COMMIT_FIELD from '@salesforce/schema/JobExecution__c.UserStoryCommit__c';
import USER_STORY_COMMIT_STATUS_FIELD from '@salesforce/schema/User_Story_Commit__c.Status__c';
import PROMOTED_USER_STORY_PROMOTION_FIELD from '@salesforce/schema/Promoted_User_Story__c.Promotion__c';
import PROMOTION_STATUS_FIELD from '@salesforce/schema/Promotion__c.Status__c';

const INFO = 'info';
const WARNING = 'warning';
const SUCCESS = 'success';
const ERROR = 'error';
const ADD = 'add';
const REMOVE = 'remove';

const IN_PROGRESS = 'In progress';
const NO_CHANGES = 'No changes';
const PENDING = 'Pending';
const COMPLETE = 'Complete';
const FAILED = 'Failed';

const USER_STORY_COMMIT = 'userStoryCommitProgressAlerts';

export const label = {
    USER_STORY_COMMIT_IN_PROGRESS_ALERT,
    USER_STORY_COMMIT_FAILED_ALERT,
    USER_STORY_COMMIT_SUCCESS_ALERT,
    USER_STORY_COMMIT_SUCCESS_ALERT_FAILED_QUALITY_CHECKS,
    USER_STORY_COMMIT_NO_CHANGES_ALERT,
    COMMIT_NO_CHANGES_FAILED_QUALITY_CHECKS,
    PROMOTION_IN_PROGRESS_ALERT
};

export const schema = {
    JOB_EXECUTION_STATUS_FIELD,
    JOB_EXECUTION_USER_STORY_COMMIT_FIELD,
    USER_STORY_COMMIT_STATUS_FIELD,
    PROMOTED_USER_STORY_PROMOTION_FIELD,
    PROMOTION_STATUS_FIELD
};

export const messageParams = {
    INFO,
    WARNING,
    SUCCESS,
    ERROR,
    ADD,
    REMOVE
};

export const commitStatus = {
    IN_PROGRESS,
    NO_CHANGES,
    PENDING,
    COMPLETE,
    FAILED
};

export const communicationName = {
    USER_STORY_COMMIT
};

export const jobStatus = {
    SUCCESSFUL: 'Successful',
    ERROR: 'Error',
    IN_PROGRESS: 'In Progress',
    NOT_STARTED: 'Not Started'
};