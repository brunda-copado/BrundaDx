import { LightningElement, api } from 'lwc';

import { labels } from './constants';
import { showToastError } from 'c/copadocoreToastNotification';

import getStopExecutionData from '@salesforce/apex/ResultMonitor.getStopExecutionData';
import stopExecution from '@salesforce/apex/ResultMonitor.stopExecution';

export default class WebhookSettingsDelete extends LightningElement {

    labels = labels;
    showSpinner = false;
    showInnerSpinner = false;
    resultId;
    stopExecutionData = {};


    @api
    showModal(resultId) {
        this.resultId = resultId;
        this.getData();
    }

    async getData() {
        try {
            this.showSpinner = true;
            this.stopExecutionData = await getStopExecutionData({resultId : this.resultId});
            this.stopExecutionData.variant = 'info';
            this.stopExecutionData.button = true;
            this.template.querySelector('c-copadocore-modal').show();
        } catch (ex) {
            showToastError(this, { message: ex.message || ex.body?.message });
        } finally {
            this.showSpinner = false;
        }
    }


    closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }


    async stopExecution() {
        try {
            this.stopExecutionData.button = false;
            this.showInnerSpinner = true;
            this.dispatchEvent(new CustomEvent('cancelling'));
            await stopExecution({resultId : this.resultId});
            this.dispatchEvent(new CustomEvent('oncancelled'));
            this.template.querySelector('c-copadocore-modal').hide();
        } catch (ex) {
            this.stopExecutionData.variant = 'error';
            this.stopExecutionData.info = this.stopExecutionData.error;
            this.stopExecutionData.message = ex.message || ex.body?.message;
        } finally {
            this.showInnerSpinner = false;
        }
    }

}