import { LightningElement, api, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { label, columns, pipelineFields} from './constants';
import activateAutomations from '@salesforce/apex/ContinuousDeliverySetupController.activateAutomations';

export default class ContinuousDeliverySetupSummary extends LightningElement {
    @api recordId;
    @api summaryData;
    @api configuration;
    @api pipelineStages;

    summaryColumns = columns;
    modalCommunicationId = 'continuousDeliverySetupSummaryAlert';
    isRendered = false;
    label = label;

    @wire(MessageContext)
    messageContext;

    get isSummaryDataLoaded() {
        return this.summaryData && this.summaryData.length !== 0;
    }

    renderedCallback() {
        if(!this.isRendered) {
            if(this.summaryData.length === 0) {
                this.messageAlert(label.CD_Setup_Summary_Warning_Message, 'warning', false, this.modalCommunicationId);
            } else {
                this.messageAlert(label.CD_Setup_Summary_Info_Message, 'info', false, this.modalCommunicationId);
            }
            this.isRendered = true;
            this.spinner('stopspinner');
        }
    }

    messageAlert(message, variant, dismissible, communicationId) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    updateConfigurationJsonField() {
        this.spinner('showspinner');
        let configurationJson = JSON.parse(JSON.stringify(this.configuration));
        delete configurationJson['promotionSettings'];
        delete configurationJson['backpromotionSettings'];

        const fields = {};
        fields[pipelineFields.ID_FIELD.fieldApiName] = this.recordId;
        fields[pipelineFields.CONTINUOUS_DELIVERY_CONFIGURATION_JSON.fieldApiName] = JSON.stringify(configurationJson);

        const recordInput = { fields };
        updateRecord(recordInput)
                .then(() => {
                    activateAutomations({ pipelineId: this.recordId, automationConfig: JSON.stringify(this.configuration) });
                    showToastSuccess(this, { message: label.Continuous_Delivery_was_set_up_successfully });
                })
                .catch(error => {
                    console.error(error);
                    showToastError(this, { message: label.Continuous_Delivery_could_not_be_set_up });
                }).finally(() => {
                    const updaterecord = new CustomEvent('updatejsonfield', {
                        detail: true
                    });

                    this.dispatchEvent(updaterecord);
                    this.spinner('stopspinner');
                });
    }

    handlePrev() {
        const stageIds = this.configuration.backpromotionSettings ? this.configuration.backpromotionSettings.uptoStage : '';
        this.selectedStage = stageIds ? this.pipelineStages.find(element => element.label === stageIds[stageIds.length - 1]).value : '';

        const previous = new CustomEvent('getprevstep', {
            detail: {
                selectedStage: this.selectedStage
            }
        });

        this.dispatchEvent(previous);
    }

    handleCancel() {
        const cancel = new CustomEvent('closemodal', {
            detail: true
        });

        this.dispatchEvent(cancel);
    }

    spinner(event) {
        const spinner = new CustomEvent(event, {
            detail: true
        });

        this.dispatchEvent(spinner);
    }
}