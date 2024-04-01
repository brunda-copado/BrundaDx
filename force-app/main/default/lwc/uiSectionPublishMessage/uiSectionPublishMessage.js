import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { showToastError } from 'c/copadocoreToastNotification';
import DYNAMIC_RENDERING_COMMUNICATION_CHANNEL from '@salesforce/messageChannel/DynamicRenderingCommunication__c';
import { MessageContext, publish, subscribe } from 'lightning/messageService';
import { reduceErrors } from 'c/copadocoreUtils';

export default class UiSectionPublishMessage extends LightningElement {
    @api targetRecordId;
    @api targetObject;
    @api targetField;
    @api requiresTestTool = false;
    @api requiresPlatform = false;
    @api requiresLocationOnly = false;
    fieldReady = false;
    uiSectionready = false;

    _injectedFields = [];
    _fieldValue;
    _uiSectionId;
    _componentsToRender = new Set();

    get fields() {
        return this._injectedFields;
    }

    @wire(MessageContext)
    _context;

    @wire(getRecord, { recordId: '$targetRecordId', fields: '$fields' })
    wiredRecord({ error, data }) {
        if (this.fields) {
            if (data) {
                const newFieldValue = getFieldValue(data, this.fields[0]);
                this.fieldReady = true;
                const fieldValueChanged = this._uiSectionId && this._fieldValue !== newFieldValue;
                this._fieldValue = newFieldValue;

                // Note: Send the new value in case of change.
                if (fieldValueChanged) {
                    if (this.fieldReady && this.uiSectionready) {
                        this._renderComponentsQueue();
                    }
                }
            } else if (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        }
    }

    connectedCallback() {
        this._injectedFields.push(this.targetObject + '.' + this.targetField);
        this._handleSubscribe();
    }

    // PRIVATE

    _handleSubscribe() {
        subscribe(this._context, DYNAMIC_RENDERING_COMMUNICATION_CHANNEL, event => {
            if ((event?.type === 'requiringTestTool' && this.requiresTestTool) || (event?.type === 'requiringPlatform' && this.requiresPlatform) || (event?.type === 'requiringLocation' && this.requiresLocationOnly)) {
                this._uiSectionId = event.name;
                this.uiSectionready = true;

                this._componentsToRender.add(this._uiSectionId);
                if (this.fieldReady && this.uiSectionready) {
                    this._renderComponentsQueue();
                }
            }
        });
    }

    _renderComponentsQueue() {
        this._componentsToRender.forEach(uiSectionId => {
            this._requestComponentToRender(uiSectionId);
            this._componentsToRender.delete(uiSectionId);
        });
    }

    _requestComponentToRender(uiSectionId) {
        const payload = {
            type: uiSectionId,
            testTool: this._testTool
        };

        if (this.requiresTestTool) {
            payload.testTool = this._fieldValue;
        } else if (this.requiresPlatform) {
            payload.platform = this._fieldValue;
        } else if(this.requiresLocationOnly){
            payload.locationOnly = true;
        }

        publish(this._context, DYNAMIC_RENDERING_COMMUNICATION_CHANNEL, payload);
    }
}