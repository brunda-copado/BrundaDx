import { LightningElement, api, track } from 'lwc';
import { reduceErrors } from 'c/copadocoreUtils';
import getJobIds from '@salesforce/apex/JobExecutionMonitorCtrl.getJobIds';

export default class JobExecutionMonitor extends LightningElement {
    @api recordId;
    @api jobExecutionField;
    @api noJobTitle;
    @api noJobMessage;

    @track jobExecutionIds = [];

    isLoading = false;
    errorMessage;

    async connectedCallback() {
        this.isLoading = true;
        try {
            this.jobExecutionIds = await getJobIds({
                recordId: this.recordId,
                fieldApiName: this.jobExecutionField
            });
        } catch (error) {
            this.errorMessage = reduceErrors(error);
        }

        this.isLoading = false;
    }

    get hasJobs() {
        return Boolean(this.jobExecutionIds.length);
    }
}