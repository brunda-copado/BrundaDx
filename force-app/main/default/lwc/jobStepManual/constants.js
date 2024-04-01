import JOB_TEMPLATE_OBJECT from '@salesforce/schema/JobTemplate__c';
import JOB_EXECUTION_OBJECT from '@salesforce/schema/JobExecution__c';
import DATA_JSON_FIELD from '@salesforce/schema/JobStep__c.ConfigJson__c';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import STAGE_DISPLAY_NAME from '@salesforce/schema/Stage__c.Display_Name__c';
import RESULT_DATA_JSON_FIELD from '@salesforce/schema/JobStep__c.ResultDataJson__c';
import JOBSTEP_JOB_TEMPLATE_FIELD from '@salesforce/schema/JobStep__c.JobTemplate__c';
import JOBSTEP_JOB_EXECUTION_FIELD from '@salesforce/schema/JobStep__c.JobExecution__c';
import JOBSTEP_EXECUTION_SEQUENCE_FIELD from '@salesforce/schema/JobStep__c.ExecutionSequence__c';

import CURRENT_USER_ID from '@salesforce/user/Id';

import Task_Description from '@salesforce/label/c.Task_Description';
import Manual_Task_Comment from '@salesforce/label/c.Manual_Task_Comment';
import Task_Assignee from '@salesforce/label/c.TASK_ASSIGNEE';
import Manual_Task_Assignment from '@salesforce/label/c.Manual_Task_Assignment';
import Error_Searching_Records from '@salesforce/label/c.Error_Searching_Records';
import COMPLETE_THIS_FIELD from '@salesforce/label/c.CompleteThisField';
import COPADO_ORG_SETUP_ORG_USERNAME from '@salesforce/label/c.COPADO_ORG_SETUP_ORG_USERNAME';
import Manual_Task_to_be_completed_on from '@salesforce/label/c.Manual_Task_to_be_completed_on';
import Manual_Task_to_be_completed_on_Helptext from '@salesforce/label/c.Manual_Task_to_be_completed_on_Helptext';
import Manual_Taks_Perform_At_Source from '@salesforce/label/c.Manual_Taks_Perform_At_Source';
import Manual_Taks_Perform_At_Destination from '@salesforce/label/c.Manual_Taks_Perform_At_Destination';
import Manual_Taks_Complete_In_Source from '@salesforce/label/c.Manual_Taks_Complete_In_Source';
import Manual_Taks_Complete_In_Destination from '@salesforce/label/c.Manual_Taks_Complete_In_Destination';
import Manual_Tasks_Asignee_Helptext from '@salesforce/label/c.Manual_Tasks_Asignee_Helptext';
import Manual_Task_Description_Helptext from '@salesforce/label/c.Manual_Task_Description_Helptext';
import Manual_Task_Disable_Options from '@salesforce/label/c.Manual_Task_Disable_Options';
import Manual_Task_Disable_for_Back_Promotions from '@salesforce/label/c.Manual_Task_Disable_for_Back_Promotions';
import Manual_Task_Disable_for_Back_Promotions_Helptext from '@salesforce/label/c.Manual_Task_Disable_for_Back_Promotions_Helptext';
import Manual_Task_Disable_For_Stages_or_Environments from '@salesforce/label/c.Manual_Task_Disable_For_Stages_or_Environments';
import Manual_Task_Disable_For_Stages_or_Environments_Helptext from '@salesforce/label/c.Manual_Task_Disable_For_Stages_or_Environments_Helptext';
import STAGES from '@salesforce/label/c.Stages';
import ENVIRONMENTS from '@salesforce/label/c.Environments';
import Enabled from '@salesforce/label/c.Enabled';
import Disabled from '@salesforce/label/c.Disabled';
import Manual_Task_Disable_For_Environment from '@salesforce/label/c.Manual_Task_Disable_For_Environment';
import Manual_Task_Disable_For_Environment_Helptext from '@salesforce/label/c.Manual_Task_Disable_For_Environment_Helptext';
import Manual_Task_Disable_For_Stage from '@salesforce/label/c.Manual_Task_Disable_For_Stage';
import Manual_Task_Disable_For_Stage_Helptext from '@salesforce/label/c.Manual_Task_Disable_For_Stage_Helptext';
import Execution_Sequence from '@salesforce/label/c.Execution_Sequence';

export const schema = {
    JOB_TEMPLATE_OBJECT,
    JOB_EXECUTION_OBJECT,
    DATA_JSON_FIELD,
    RESULT_DATA_JSON_FIELD,
    NAME_FIELD,
    EMAIL_FIELD,
    STAGE_DISPLAY_NAME,
    JOBSTEP_JOB_TEMPLATE_FIELD,
    JOBSTEP_JOB_EXECUTION_FIELD,
    JOBSTEP_EXECUTION_SEQUENCE_FIELD
};

export const constant = {
    CURRENT_USER_ID
};

export const label = {
    Task_Description,
    Manual_Task_Comment,
    Task_Assignee,
    Manual_Task_Assignment,
    Error_Searching_Records,
    COMPLETE_THIS_FIELD,
    COPADO_ORG_SETUP_ORG_USERNAME,
    Manual_Task_to_be_completed_on,
    Manual_Task_to_be_completed_on_Helptext,
    Manual_Tasks_Asignee_Helptext,
    Manual_Task_Description_Helptext,
    Manual_Task_Disable_Options,
    Manual_Task_Disable_for_Back_Promotions,
    Manual_Task_Disable_for_Back_Promotions_Helptext,
    Manual_Task_Disable_For_Stages_or_Environments,
    Manual_Task_Disable_For_Stages_or_Environments_Helptext,
    STAGES,
    ENVIRONMENTS,
    Enabled,
    Disabled,
    Manual_Task_Disable_For_Environment,
    Manual_Task_Disable_For_Environment_Helptext,
    Manual_Task_Disable_For_Stage,
    Manual_Task_Disable_For_Stage_Helptext,
    Manual_Taks_Perform_At_Source,
    Manual_Taks_Perform_At_Destination,
    Manual_Taks_Complete_In_Source,
    Manual_Taks_Complete_In_Destination,
    Execution_Sequence
};

const SOURCE = 'source';
const DESTINATION = 'destination';
export const PERFORM_AT_OPTION_VALUES = {
    SOURCE,
    DESTINATION
};

export const performAtOptions = [
    { label: Manual_Taks_Perform_At_Source, value: PERFORM_AT_OPTION_VALUES.SOURCE },
    { label: Manual_Taks_Perform_At_Destination, value: PERFORM_AT_OPTION_VALUES.DESTINATION }
];

const STAGES_VALUE = 'Stages';
const ENVIRONMENTS_VALUE = 'Environments';
export const SCOPE_MODE_OPTION_VALUES = {
    STAGES_VALUE,
    ENVIRONMENTS_VALUE
};

export const scopeModeOptions = [
    { label: label.STAGES, value: SCOPE_MODE_OPTION_VALUES.STAGES_VALUE },
    { label: label.ENVIRONMENTS, value: SCOPE_MODE_OPTION_VALUES.ENVIRONMENTS_VALUE }
];

const ASSIGNEE_ID = 'assigneeId';
const ASSIGNEE_NAME = 'assigneeName';
const PERFORM_AT_SOURCE = 'performAtSource';
const PERFORM_AT_DESTINATION = 'performAtDestination';
const DISABLE_FOR_BACK_PROMOTIONS = 'disableForBackPromotions';
const DISABLED_STAGES = 'disabledStages';
const DISABLED_ENVIRONMENTS = 'disabledEnvironments';

export const PARAMETERS = {
    ASSIGNEE_ID,
    ASSIGNEE_NAME,
    PERFORM_AT_SOURCE,
    PERFORM_AT_DESTINATION,
    DISABLE_FOR_BACK_PROMOTIONS,
    DISABLED_STAGES,
    DISABLED_ENVIRONMENTS
};