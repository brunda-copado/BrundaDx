import { LightningElement, api } from 'lwc';
import getDeploymentSteps from '@salesforce/apex/DataSetExecutionHistoryCtrl.getDeploymentSteps';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { label, schema } from './constants';

const columns = [
    {
        label: label.DEPLOYMENT,
        fieldName: 'DeploymentLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'DeploymentName' }, target: '_blank' }
    },
    { label: label.STEP_NAME, fieldName: 'StepName', type: 'text' },
    { label: label.STATUS, fieldName: 'StepStatus', type: 'text' },
    {
        label: label.DATE,
        fieldName: 'DeploymentDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }
];

export default class DataSetExecutionHistory extends LightningElement {
    @api recordId;

    label = label;
    schema = schema;

    columns = columns;
    data;

    showSpinner = false;

    async connectedCallback() {
        this.showSpinner = true;
        try {
            const steps = await getDeploymentSteps({ recordId: this.recordId });
            this.data = this._createTableRows(steps);
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
        this.showSpinner = false;
    }

    _createTableRows(steps) {
        return steps.map((step) => {
            return {
                Id: step[schema.STEP_ID.fieldApiName],
                DeploymentName: step[schema.STEP_DEPLOYMENT.fieldApiName.replace('__c', '__r')][schema.DEPLOYMENT_NAME.fieldApiName],
                DeploymentLink: '/' + step[schema.STEP_DEPLOYMENT.fieldApiName.replace('__c', '__r')][schema.DEPLOYMENT_ID.fieldApiName],
                StepName: step[schema.STEP_NAME_FIELD.fieldApiName],
                StepStatus: step[schema.STEP_STATUS.fieldApiName],
                DeploymentDate: step[schema.STEP_DEPLOYMENT.fieldApiName.replace('__c', '__r')][schema.DEPLOYMENT_DATE.fieldApiName]
            };
        });
    }
}