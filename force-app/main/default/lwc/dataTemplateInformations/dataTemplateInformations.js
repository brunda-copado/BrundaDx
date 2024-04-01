import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { schema, images, labels } from './constants';
import { namespace } from 'c/copadocoreUtils';

import getRelatedObjectCount from '@salesforce/apex/DataTemplateInformationsCtrl.getRelatedObjectCount';

export default class DataTemplateInformations extends NavigationMixin(LightningElement) {
    @api templateId;

    schema = schema;
    images = images;
    labels = labels;

    //Data Template
    templateName;
    templateMainObject;
    templateSourceOrg;
    templateMaxRecords;
    templateBatchSize;
    templateTotalRelatedObjects;

    //url
    templatePageUrl;
    erdDiagramUrl;

    connectedCallback() {
        this._fetchRelatedObjectCount();
        this._generateTemplateDetailUrl();
        this._generateErdDiagramUrl();
    }

    @wire(getRecord, {
        recordId: '$templateId',
        fields: [
            schema.DATA_TEMPLATE_NAME,
            schema.DATA_TEMPLATE_MAIN_OBJECT,
            schema.DATA_TEMPLATE_SOURCE_ORG,
            schema.DATA_TEMPLATE_MAX_RECORDS,
            schema.DATA_TEMPLATE_BATCH_SIZE
        ]
    })
    getDataTemplateDetails({ error, data }) {
        if (data) {
            this.templateName = getFieldValue(data, schema.DATA_TEMPLATE_NAME);
            this.templateMainObject = getFieldValue(data, schema.DATA_TEMPLATE_MAIN_OBJECT);
            this.templateSourceOrg = getFieldValue(data, schema.DATA_TEMPLATE_SOURCE_ORG);
            this.templateMaxRecords = getFieldValue(data, schema.DATA_TEMPLATE_MAX_RECORDS);
            this.templateBatchSize = getFieldValue(data, schema.DATA_TEMPLATE_BATCH_SIZE);
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    _generateTemplateDetailUrl() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.templateId,
                actionName: 'view'
            }
        }).then(url => {
            this.templatePageUrl = url;
        });
    }

    _generateErdDiagramUrl() {
        let nameSpace = namespace == '' ? 'c' : 'copado';
        let compDefinition = {
            componentDef: `${nameSpace}:addRelationalDiagramContainer`,
            attributes: {
                recordId: this.templateId
            }
        };
        // Base64 encode the compDefinition JS object
        try {
            let encodedCompDef = btoa(JSON.stringify(compDefinition));
            this.erdDiagramUrl = `/one/one.app#${encodedCompDef}`;
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async _fetchRelatedObjectCount() {
        try {
            this.templateTotalRelatedObjects = await getRelatedObjectCount({ templateId: this.templateId });
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    get maximumRecordLimit() {
        return this.templateMaxRecords ? this.templateMaxRecords : 'Unlimited';
    }

    get nameAndMainObjectInfo() {
        return `${this.templateName} | ${this.templateMainObject}`;
    }
}