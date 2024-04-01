import { LightningElement, api } from 'lwc';
import getAttachment from '@salesforce/apex/ReadFromAttachmentCtrl.getAttachment';
import { handleAsyncError } from 'c/copadocoreUtils';

const columns = [
    { label: 'Name', fieldName: 'n', type: 'text' },
    { label: 'Type', fieldName: 't', type: 'text' },
    { label: 'Retrieve Only', fieldName: 'r', type: 'boolean' },
    { label: 'Created by', fieldName: 'cb', type: 'text' },
    { label: 'Created date', fieldName: 'cd', type: 'text' }
];

export default class ReadFromAttachment extends LightningElement {
    // Required
    @api recordId;
    @api name;
    columns = columns;
    data = [];

    showSpinner;

    async connectedCallback() {
        const safeGetAttachment = handleAsyncError(this._getAttachment, { title: 'Error' });

        const result = await safeGetAttachment(this, { parentId: this.recordId, name: this.name });
        if (result) {
            this.data = JSON.parse(atob(result));
        }
    }

    _getAttachment(self, params) {
        return getAttachment(params);
    }
}