import { LightningElement, api } from 'lwc';
import JOB_STEP_OBJECT from '@salesforce/schema/JobStep__c';
import EXTENSION_TOOL from '@salesforce/schema/JobStep__c.Quality_Gate_Rule_Condition__r.Extension_Configuration__r.ExtensionTool__c';

export default class TestJobStepPublishMessage extends LightningElement {
    @api recordId;

    stepObject = JOB_STEP_OBJECT.objectApiName;
    extensionTool = EXTENSION_TOOL.fieldApiName;
}