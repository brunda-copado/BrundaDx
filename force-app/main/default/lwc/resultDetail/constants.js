import CLOSE from '@salesforce/label/c.CLOSE';
import LOADING from '@salesforce/label/c.LOADING';
import PENDING from '@salesforce/label/c.PENDING';
import STEP_TYPE_MANUAL_TASK from '@salesforce/label/c.STEP_TYPE_MANUAL_TASK';
import MORE_OPTIONS from '@salesforce/label/c.More_Options';
import UPDATE_MANUAL_TASK_BUTTON from '@salesforce/label/c.Update_Manual_Task_Button';
import TYPE from '@salesforce/label/c.TYPE';
import STATUS from '@salesforce/label/c.STATUS';
import UpdateStepProgress from '@salesforce/label/c.UpdateStepProgress';
import ManageJobQueueHeader from '@salesforce/label/c.ManageJobQueueHeader';
import ReleaseResourcePrompt from '@salesforce/label/c.ReleaseResourcePrompt';
import ReleaseQueueInstruction from '@salesforce/label/c.ReleaseQueueInstruction';
import RefreshTable from '@salesforce/label/c.RefreshTable';
import ReleaseResource from '@salesforce/label/c.ReleaseResource';
import Task from '@salesforce/label/c.Task';
import Context from '@salesforce/label/c.Context';
import Owner from '@salesforce/label/c.Owner';
import TaskInProgress from '@salesforce/label/c.TaskInProgress';
import Queue from '@salesforce/label/c.Queue';
import SUCCESS from '@salesforce/label/c.SUCCESS';
import ERROR from '@salesforce/label/c.ERROR';
import INPROGRESS from '@salesforce/label/c.SprintWall_In_Progress';
import DETAILS from '@salesforce/label/c.DETAILS';
import CANCELLATION from '@salesforce/label/c.Cancellation';
import ContinueQueueForFailedJob from '@salesforce/label/c.ContinueQueueForFailedJob';
import ContinueQueueForInProgressJob from '@salesforce/label/c.ContinueQueueForInProgressJob'

import ICONS from '@salesforce/resourceUrl/ResultMonitorIconSet';

export const labels = {
    Task,
    CLOSE,
    Context,
    Queue,
    Owner,
    LOADING,
    PENDING,
    STEP_TYPE_MANUAL_TASK,
    MORE_OPTIONS,
    UPDATE_MANUAL_TASK_BUTTON,
    TYPE,
    STATUS,
    RefreshTable,
    TaskInProgress,
    ReleaseResource,
    UpdateStepProgress,
    ManageJobQueueHeader,
    ReleaseResourcePrompt,
    ReleaseQueueInstruction,
    SUCCESS,
    ERROR,
    INPROGRESS,
    DETAILS,
    CANCELLATION,
    ContinueQueueForFailedJob,
    ContinueQueueForInProgressJob
};

const TEST_ERROR_ICON = ICONS + '/ErrorTestStep.svg';
const TEST_SUCCESS_ICON = ICONS + '/SuccessTestStep.svg';
const TEST_IN_PROGRESS_ICON = ICONS + '/InProgressTestStep.svg';
const TEST_NOT_STARTED_ICON = ICONS + '/NotStartedTestStep.svg';

const IN_PROGRESS = 'In Progress';
const BLOCKED = 'Blocked';

export const images = {
    TEST_ERROR_ICON,
    TEST_SUCCESS_ICON,
    TEST_IN_PROGRESS_ICON,
    TEST_NOT_STARTED_ICON,
};

export const queueStatus = {
    IN_PROGRESS,
    BLOCKED
}