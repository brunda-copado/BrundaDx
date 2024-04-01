import { LightningElement, api } from 'lwc';

import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { CloseActionScreenEvent } from 'lightning/actions';
import { reduceErrors } from 'c/copadocoreUtils';
import { schema, label } from './constants';

export default class ExtensionConfigurationDeactivation extends LightningElement {
    @api recordId;

    label = label;
    schema = schema;
    isExecuting = false;

    async handleDeactivation() {
        if (!this.isExecuting) {
            this.isExecuting = true;
            try {
                const fields = {};
                fields[schema.Id.fieldApiName] = this.recordId;
                fields[schema.Active.fieldApiName] = false;

                await updateRecord({ fields });

                getRecordNotifyChange([{ recordId: this.recordId }]);
                showToastSuccess(this, { message: label.SUCCESS_MESSAGE });
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
            this.isExecuting = false;
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}