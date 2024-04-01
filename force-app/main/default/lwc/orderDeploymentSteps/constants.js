import NAME from '@salesforce/label/c.NAME';
import TYPE from '@salesforce/label/c.TYPE';
import USER_STORY from '@salesforce/label/c.USER_STORY';
import USER_STORY_TITLE from '@salesforce/label/c.User_Story_Title';
import Job_Steps from '@salesforce/label/c.Job_Steps';
import Order_Job_Steps from '@salesforce/label/c.Order_Job_Steps';
import Before_Deployment from '@salesforce/label/c.Before_Deployment';
import After_Deployment from '@salesforce/label/c.After_Deployment';
import No_Deployment_Steps from '@salesforce/label/c.No_Deployment_Steps';
import No_Deployment_Steps_To_Run from '@salesforce/label/c.No_Deployment_Steps_To_Run';
import Deployment_Steps from '@salesforce/label/c.DEPLOYMENT_STEPS';
import LOADING from '@salesforce/label/c.LOADING';
import Drag_Drop_Order from '@salesforce/label/c.Drag_Drop_Order';
import Error_Value from '@salesforce/label/c.Error_Value';
import Delete from '@salesforce/label/c.DELETE';

import NAME_FIELD from '@salesforce/schema/JobStep__c.Name';
import CUSTOM_TYPE_FIELD from '@salesforce/schema/JobStep__c.CustomType__c';
import ORDER_FIELD from '@salesforce/schema/JobStep__c.Order__c';
import EXECUTION_SEQUENCE_FIELD from '@salesforce/schema/JobStep__c.ExecutionSequence__c';
import USER_STORY_FIELD from '@salesforce/schema/JobStep__c.UserStory__c';
import USER_STORY_ID_FIELD from '@salesforce/schema/User_Story__c.Id';
import USER_STORY_NAME_FIELD from '@salesforce/schema/User_Story__c.Name';
import USER_STORY_TITLE_FIELD from '@salesforce/schema/User_Story__c.User_Story_Title__c';

export const labels = {
    NAME,
    TYPE,
    USER_STORY,
    USER_STORY_TITLE,
    Job_Steps,
    Order_Job_Steps,
    Before_Deployment,
    After_Deployment,
    No_Deployment_Steps,
    No_Deployment_Steps_To_Run,
    Deployment_Steps,
    LOADING,
    Drag_Drop_Order,
    Error_Value,
    Delete
};

export const schema = {
    NAME_FIELD,
    CUSTOM_TYPE_FIELD,
    ORDER_FIELD,
    EXECUTION_SEQUENCE_FIELD,
    USER_STORY_FIELD,
    USER_STORY_ID_FIELD,
    USER_STORY_NAME_FIELD,
    USER_STORY_TITLE_FIELD
};

export const tableColumns = [
    {
        hideDefaultActions: true,
        fixedWidth: 62,
        cellAttributes: { iconName: 'utility:drag_and_drop', iconAlternativeText: Drag_Drop_Order }
    },
    { label: NAME, fieldName: NAME_FIELD.fieldApiName, hideDefaultActions: true },
    { label: TYPE, fieldName: CUSTOM_TYPE_FIELD.fieldApiName, hideDefaultActions: true },
    {
        label: USER_STORY,
        fieldName: 'userStoryLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'userStoryName' }, target: '_blank' }
    },

    { label: USER_STORY_TITLE, fieldName: 'userStoryTitle', hideDefaultActions: true },

    {
        hideDefaultActions: true,
        fixedWidth: 62,
        type: 'button-icon',
        typeAttributes: { iconName: 'utility:delete', variant: 'bare' },

        cellAttributes: { alternativeText: Delete, alignment: 'right' }
    }
];