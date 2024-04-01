import { LightningElement, api, wire } from 'lwc';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import getTool from '@salesforce/apex/ResultViewerPublishMessageCtrl.getTool';
import { MessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';
import DYNAMIC_RENDERING_COMMUNICATION_CHANNEL from '@salesforce/messageChannel/DynamicRenderingCommunication__c';

export default class ResultViewerPublishMessage extends LightningElement {
    @api recordId;

    uiSectionReady = false;

    _subscription;
    _fieldValue;
    _uiSectionId;
    _componentsToRender = new Set();

    @wire(MessageContext)
    _context;


    async connectedCallback() {

        if (!this._subscription) {
            this._subscription = this._handleSubscribe();
        }

        try {
            this._testTool = await getTool({ resultId: this.recordId});
            if (this._testTool && this.uiSectionReady) {
                this._renderComponentsQueue();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    disconnectedCallback() {
        unsubscribe(this._subscription);
        this._subscription = null;
    }

    // PRIVATE

    _handleSubscribe() {
        return subscribe(this._context, DYNAMIC_RENDERING_COMMUNICATION_CHANNEL, event => {
            if (event?.type === 'requiringTestTool') {
                this._uiSectionId = event.name;
                this.uiSectionReady = true;

                this._componentsToRender.add(this._uiSectionId);
                if(this._testTool) {
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

        publish(this._context, DYNAMIC_RENDERING_COMMUNICATION_CHANNEL, payload);
    }
}