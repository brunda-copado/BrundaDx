import { LightningElement, api, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { label, schema } from './constants';
import { validateInputs, formatLabel } from './utils';
import { ACTIVATE_ALERT_ID, DATATEMPLATE_COMMUNICATION_ID, createAlert } from 'c/datatemplateUtil';

import validateOrg from '@salesforce/apex/DataTemplateDefineDataSourceCtrl.validateOrg';
import fetchObjects from '@salesforce/apex/DataTemplateDefineDataSourceCtrl.fetchObjects';
import setDataTemplateDataSource from '@salesforce/apex/DataTemplateDefineDataSourceCtrl.setDataTemplateDataSource';

export default class DataTemplateDefineDataSourceModal extends LightningElement {
    label = label;
    schema = schema;
    modalSize = 'small';
    @api recordId;

    // alerts
    @wire(MessageContext)
    messageContext;

    communicationId = 'dataTemplateDefineSourceErrors';

    showSpinner = false;

    // inputs
    sourceOrg;
    objectOptions = [];
    mainObject;

    // validation popover
    validInputs = true;
    validOrg = false;
    mainObjectErrors = [];

    @api
    show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    get saveDisabled() {
        return this.showSpinner;
    }

    async handleChangeSourceOrg(event) {
        try {
            this.showSpinner = true;

            this._clearAlerts();

            this.sourceOrg = event.detail.value[0];

            if (this.sourceOrg) {
                this.validOrg = await validateOrg({ orgId: this.sourceOrg });

                if (this.validOrg) {
                    this.objectOptions = await fetchObjects({ orgId: this.sourceOrg });
                    this._initLookupDefaultResults();
                } else {
                    this._showValidationAlert(this.sourceOrg);
                }
            } else {
                this._resetInputs();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async handleSearchMainObject(event) {
        const searchTerm = event.detail.searchTerm;
        const lookupElement = event.target;
        if (lookupElement) {
            const result = this.objectOptions.filter((option) => option.label.toLowerCase().indexOf(searchTerm.toLowerCase()) !== -1);
            lookupElement.setSearchResults(result.map((option) => ({ id: option.value, title: option.label })));
        }
    }

    handleChangeMainObject(event) {
        this.mainObject = event.detail.length > 0 ? event.detail[0] : null;
        if (this.mainObject) {
            this.mainObjectErrors = [];
        }
    }

    handleClickCancel(event) {
        this._clearAlerts();
        this._resetInputs();
        this._resetValidations();
        this._closeModal();
    }

    async handleClickSave(event) {
        try {
            this.showSpinner = true;

            this.validInputs = this._validateInputs();

            if (this.validInputs) {
                await this._updateAttachments();
                await this._updateDataTemplate();
                this._closeModal();
                showToastSuccess(this, { message: label.DATA_TEMPLATE_SUCCESS_UPDATE });
                this._removeAlerts();
            } else {
                this._openErrorPopOver();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async _updateDataTemplate() {
        const fields = {};
        fields[schema.ID_FIELD.fieldApiName] = this.recordId;
        fields[schema.SOURCE_ORG_FIELD.fieldApiName] = this.sourceOrg;
        fields[schema.MAIN_OBJECT_FIELD.fieldApiName] = this.mainObject;

        await updateRecord({ fields });
    }

    async _updateAttachments() {
        await setDataTemplateDataSource({ recordId: this.recordId, orgId: this.sourceOrg, mainObject: this.mainObject });
    }

    _showValidationAlert(orgId) {
        const alertMessage = formatLabel(label.ORG_NOT_AUTHENTICATED, '/' + orgId);
        const orgAlert = createAlert(alertMessage, 'error', true, this.communicationId);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, orgAlert);
    }

    _closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    _clearAlerts() {
        const alerts = this.template.querySelector('c-copado-alert-place-holder');
        if (alerts) {
            alerts.clear();
        }
    }

    _openErrorPopOver() {
        const popover = this.template.querySelector('c-copadocore-error-popover');
        if (popover) {
            popover.openPopOver();
        }
    }

    _resetInputs() {
        this.sourceOrg = null;
        this.mainObject = null;
        this.objectOptions = [];
        const lookup = this.template.querySelector('c-lookup');
        lookup.handleClearSelection();
    }

    _resetValidations() {
        this.validInputs = true;
        this.validOrg = false;
        this.mainObjectErrors = [];
    }

    _validateInputs() {
        this._validateLookup();
        return (
            validateInputs([...this.template.querySelectorAll('[data-id="sourceOrg"]')]) === true &&
            this.sourceOrg != null &&
            this.sourceOrg !== 'undefined' &&
            this.validOrg === true &&
            this.mainObject != null &&
            this.mainObject !== 'undefined'
        );
    }

    _validateLookup() {
        if (!this.mainObject) {
            this.mainObjectErrors = [{ id: label.COMPLETE_THIS_FIELD, message: label.COMPLETE_THIS_FIELD }];
        }
    }

    _initLookupDefaultResults() {
        const lookup = this.template.querySelector('c-lookup');
        if (lookup) {
            lookup.setDefaultResults(this.objectOptions.map((option) => ({ id: option.value, title: option.label })));
        }
    }

    _removeAlerts() {
        const alert = createAlert(null, null, null, DATATEMPLATE_COMMUNICATION_ID, ACTIVATE_ALERT_ID, 'remove');
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alert);
    }
}