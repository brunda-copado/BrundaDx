import DEPLOYMENT from '@salesforce/label/c.DEPLOYMENT';
import STEP_NAME from '@salesforce/label/c.STEP_NAME';
import STATUS from '@salesforce/label/c.STATUS';
import DATE from '@salesforce/label/c.DATE';

import STEP_STATUS from '@salesforce/schema/Step__c.Status__c';
import STEP_NAME_FIELD from '@salesforce/schema/Step__c.Name';
import STEP_ID from '@salesforce/schema/Step__c.Id';
import STEP_DEPLOYMENT from '@salesforce/schema/Step__c.Deployment__c';
import DEPLOYMENT_DATE from '@salesforce/schema/Deployment__c.Date__c';
import DEPLOYMENT_NAME from '@salesforce/schema/Deployment__c.Name';
import DEPLOYMENT_ID from '@salesforce/schema/Deployment__c.Id';

export const label = {
    DEPLOYMENT,
    STEP_NAME,
    STATUS,
    DATE
};

export const schema = {
    STEP_STATUS,
    STEP_NAME_FIELD,
    STEP_ID,
    STEP_DEPLOYMENT,
    DEPLOYMENT_DATE,
    DEPLOYMENT_NAME,
    DEPLOYMENT_ID
};