import Cancel from '@salesforce/label/c.Cancel';
import Update_Manual_Task from '@salesforce/label/c.Update_Manual_Task';
import UPDATE_BUTTON from '@salesforce/label/c.UPDATE_BUTTON';
import Manual_Task_Comments from '@salesforce/label/c.Manual_Task_Comments';
import Complete_Manual_Task_Info from '@salesforce/label/c.Complete_Manual_Task_Info';
import Job_Step_Manual_Update from '@salesforce/label/c.Job_Step_Manual_Update';
import Result_Record_Required from '@salesforce/label/c.Result_Record_Required';
import Task_New_Status from '@salesforce/label/c.Task_New_Status';
import Task_Current_Status from '@salesforce/label/c.Task_Current_Status';
import Pending from '@salesforce/label/c.PENDING';
import Comment from '@salesforce/label/c.Comment';
import Error_Value from '@salesforce/label/c.Error_Value';
import Complete from '@salesforce/label/c.Complete';
import Incomplete from '@salesforce/label/c.Incomplete';
import Manual_Task_Details from '@salesforce/label/c.Manual_Task_Details';
import Task_Description from '@salesforce/label/c.DeploymentTask_Task_Description';
import Complete_In_Source_Environment from '@salesforce/label/c.Complete_in_source_environment_org';
import Complete_In_Destination_Environment from '@salesforce/label/c.Complete_in_destination_environment_org';

import STATUS_FIELD from '@salesforce/schema/JobStep__c.Status__c';
import RESULT_FIELD from '@salesforce/schema/JobStep__c.Result__c';
import RESULT_DATA_JSON_FIELD from '@salesforce/schema/JobStep__c.ResultDataJson__c';
import CONFIG_JSON_FIELD from '@salesforce/schema/JobStep__c.ConfigJson__c';
import SOURCE_ENVIRONMENT from '@salesforce/schema/JobStep__c.JobExecution__r.Source__r.Name';
import DESTINATION_ENVIRONMENT from '@salesforce/schema/JobStep__c.JobExecution__r.Destination__r.Name';

export const labels = {
    Cancel,
    Task_Current_Status,
    Task_New_Status,
    Update_Manual_Task,
    UPDATE_BUTTON,
    Manual_Task_Comments,
    Complete_Manual_Task_Info,
    Job_Step_Manual_Update,
    Result_Record_Required,
    Pending,
    Comment,
    Error_Value,
    Complete,
    Incomplete,
    Manual_Task_Details,
    Complete_In_Source_Environment,
    Complete_In_Destination_Environment,
    Task_Description
};

export const schema = {
    STATUS_FIELD,
    RESULT_FIELD,
    RESULT_DATA_JSON_FIELD,
    CONFIG_JSON_FIELD,
    SOURCE_ENVIRONMENT,
    DESTINATION_ENVIRONMENT
};

export const statusOptions = [
    { label: labels.Pending, value: 'Pending' },
    { label: labels.Complete, value: 'Complete' },
    { label: labels.Incomplete, value: 'Incomplete' }
];