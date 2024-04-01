import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { label, schema } from './constants';

export default class DataTemplateDefineDataSource extends LightningElement {
    label = label;
    schema = schema;

    @api recordId;

    sourceOrg;
    mainObject;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.SOURCE_ORG_FIELD, schema.MAIN_OBJECT_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.sourceOrg = data.fields[schema.SOURCE_ORG_FIELD.fieldApiName].value;
            this.mainObject = data.fields[schema.MAIN_OBJECT_FIELD.fieldApiName].value;
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    get dataSourceDefined() {
        return this.sourceOrg && this.mainObject;
    }

    handleClickDefineDataSource(event) {
        const dataSourceModal = this.template.querySelector('c-data-template-define-data-source-modal');
        dataSourceModal.show();
    }
}