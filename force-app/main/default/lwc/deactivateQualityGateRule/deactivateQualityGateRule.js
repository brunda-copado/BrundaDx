import { LightningElement, api } from 'lwc';
import { getRecordNotifyChange, updateRecord } from 'lightning/uiRecordApi';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

import { label, schema } from './constants';

export default class DeactivateQualityGateRule extends LightningElement {
    @api recordId;

    _isExecuting = false;

    @api
    async invoke() {
        if (!this._isExecuting) {
            this._isExecuting = true;
            try {
                const fields = {};
                fields[schema.ID_FIELD.fieldApiName] = this.recordId;
                fields[schema.STATUS_FIELD.fieldApiName] = 'Inactive';
                await updateRecord({ fields });
                getRecordNotifyChange([{ recordId: this.recordId }]);
                showToastSuccess(this, { message: label.QUALITY_GATE_DEACTIVATED });
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
            this._isExecuting = false;
        }
    }
}