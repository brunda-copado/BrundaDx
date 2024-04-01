import { LightningElement, api } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';

import Cancel from '@salesforce/label/c.Cancel';
import DELETE from '@salesforce/label/c.DELETE';
import Delete_Confirmation from '@salesforce/label/c.Delete_Confirmation';
import Error_Deleting_Record from '@salesforce/label/c.Error_Deleting_Record';
import Record_Deleted_Successfully from '@salesforce/label/c.Record_Deleted_Successfully';

export default class RelatedListDeletePopup extends LightningElement {
    label = {
        Cancel,
        DELETE,
        Delete_Confirmation,
        Error_Deleting_Record,
        Record_Deleted_Successfully
    };

    @api recordId;
    @api sobjectLabel;

    get body() {
        return `${this.label.Delete_Confirmation} ${this.sobjectLabel ? this.sobjectLabel.toLowerCase() : ''}?`;
    }

    get title() {
        return `${this.label.DELETE} ${this.sobjectLabel}`;
    }

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    handleCancel() {
        this.hide();
    }

    async handleDelete() {
        this.hide();

        try {
            await deleteRecord(this.recordId);
            showToastSuccess(this, {
                title: `${this.sobjectLabel} ${this.label.Record_Deleted_Successfully}.`
            });
            this.dispatchEvent(new CustomEvent('recorddeleted'));
        } catch(error) {
            showToastError(this, {
                message: reduceErrors(error),
                title: this.label.Error_Deleting_Record
            });
        }
    }
}