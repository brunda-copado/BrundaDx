import NAME_FIELD from '@salesforce/schema/JobTemplate__c.Name';
import VERSION_FIELD from '@salesforce/schema/JobTemplate__c.Version__c';
import DESCRIPTION_FIELD from '@salesforce/schema/JobTemplate__c.Description__c';
import OwnerId from '@salesforce/schema/JobTemplate__c.OwnerId';

import CANCEL from '@salesforce/label/c.Cancel';
import CLONE_TEMPLATE from '@salesforce/label/c.Clone_Template';
import CLONE_JOB_TEMPLATE from '@salesforce/label/c.Clone_Job_Template';
import CLONE_JOB_TEMPLATE_HEADER from '@salesforce/label/c.Clone_Job_Template_Header';
import CLONE_JOB_TEMPLATE_SUCCESS from '@salesforce/label/c.Clone_Job_Template_Success';
import ERROR from '@salesforce/label/c.ERROR';
import LOADING from '@salesforce/label/c.LOADING';

export const labels = {
    CANCEL,
    CLONE_TEMPLATE,
    CLONE_JOB_TEMPLATE,
    CLONE_JOB_TEMPLATE_HEADER,
    CLONE_JOB_TEMPLATE_SUCCESS,
    ERROR,
    LOADING
};

export const fields = [
    {
        fieldName: NAME_FIELD.fieldApiName,
        size: 6
    },
    {
        fieldName: VERSION_FIELD.fieldApiName,
        size: 6
    },
    {
        fieldName: OwnerId.fieldApiName,
        size: 6,
        isOwnerId: true
    },
    {
        fieldName: DESCRIPTION_FIELD.fieldApiName,
        size: 12
    }
];