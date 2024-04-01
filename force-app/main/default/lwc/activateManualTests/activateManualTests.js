import { LightningElement, wire } from 'lwc';

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';

import activate from '@salesforce/apex/ActivateManualTestsCtrl.activate';

import { labels, schema } from './constants';

export default class ActivateManualTests extends NavigationMixin(LightningElement) {
    recordId;
    isLoading = false;
    labels = labels;
    schema = schema;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [schema.NAME_FIELD]
    })
    record;

    //GETTER

    get name() {
        return getFieldValue(this.record.data, schema.NAME_FIELD);
    }

    async connectedCallback() {
        await this._activate();
    }

    //PRIVATE

    async _activate() {
        try {
            this.isLoading = true;

            const result = await activate({ extensionConfigId: this.recordId });
            if (result === true) {
                showToastSuccess(this, { message: labels.extensionConfigurationSuccessfullyActivated });
            } else {
                showToastError(this, { message: labels.errorNoAcceptanceCriteriaFound.replace(/{(\w+)}/g, this.name) });
            }
        } catch (error) {
            showToastError(this, { message: error.body ? error.body.message : error.message });
        } finally {
            this._closeModal();
            this.isLoading = false;
            getRecordNotifyChange([{ recordId: this.recordId }]);
        }
    }

    _closeModal() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}