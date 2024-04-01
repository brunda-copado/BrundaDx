import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { labels, schema } from './constants';
import { reduceErrors, formatLabel } from 'c/copadocoreUtils';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import executeAction from '@salesforce/apex/TakeSnapshotActionCtrl.executeAction';

export default class TakeSnapshotAction extends LightningElement {
    @api recordId;

    labels = labels;
    schema = schema;

    infoAlert;
    message = labels.COPADO_SNAPSHOT;

    showSpinner = true;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.CREDENTIAL_NAME, schema.BRANCH] })
    getSnapshotRecord({ error, data }) {
        if (data) {
            const credential = getFieldValue(data, schema.CREDENTIAL_NAME);
            const branch = getFieldValue(data, schema.BRANCH);
            this.infoAlert = formatLabel(labels.TAKE_SNAPSHOT_INFO_MESSAGE, [credential, branch]);
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
        this.showSpinner = false;
    }

    handleChangeMessage(event) {
        this.message = event.target.value;
    }

    async takeSnapshot(event) {
        try {
            this.showSpinner = true;
            event.preventDefault();
            if (this._validateFields()) {
                await executeAction({ snapshotId: this.recordId, message: this.message });
                this.closeQuickAction();
                showToastSuccess(this, { message: labels.TOAST_SUCCESS });
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    _validateFields() {
        return [...this.template.querySelectorAll('lightning-input-field')].reduce((validSoFar, field) => {
            return validSoFar && field.reportValidity();
        }, true);
    }
}