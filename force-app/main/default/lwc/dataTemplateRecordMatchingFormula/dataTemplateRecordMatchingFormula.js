import { LightningElement, api, track, wire } from 'lwc';
import { labels, schema } from './constants';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { prepareFieldsForCombobox, adjustFieldsWithReference, adjustReference, getFieldLabelFromSelectOptions } from './utils';
import { NavigationMixin } from 'lightning/navigation';

import getObjectFields from '@salesforce/apex/DataTemplateRecordMatchingFormulaCtrl.getObjectFields';
import getRecordMatchingFormula from '@salesforce/apex/DataTemplateRecordMatchingFormulaCtrl.getRecordMatchingFormula';
import checkCredentialAccess from '@salesforce/apex/DataTemplateRecordMatchingFormulaCtrl.checkCredentialAccess';
import getDataTemplate from '@salesforce/apex/DataTemplateRecordMatchingFormulaCtrl.getDataTemplate';

import { updateRecord, createRecord, getFieldValue } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { validateCredential } from 'c/copadoCredentialValidator';
import { RECORD_MATCHING_FORMULA_ID, createAlert, DATATEMPLATE_COMMUNICATION_ID } from 'c/datatemplateUtil';
export default class DataTemplateRecordMatchingFormula extends NavigationMixin(LightningElement) {
    @wire(MessageContext)
    messageContext;

    modalSize = 'small';
    labels = labels;
    schema = schema;

    @api templateId; // dataTemplate recordId;
    @api readOnlyMode;

    showSpinner = false;

    recordId; // recordmatching formula id
    recordMatchingFormula;
    dataTemplate;
    hasCredentialAccess = true;
    validCredential = false;
    formulaName;
    hashFormula;

    selectedMainObject;
    maiObjectLabel;

    _mainObjectOriginalFields;
    _otherObjectOriginalFields;
    @track
    mainObjectFields;

    selectedField1;
    selectedField2;
    selectedField3;

    selectedField1Secondary = '';
    selectedField2Secondary = '';
    selectedField3Secondary = '';

    secondaryOptions1;
    secondaryOptions2;
    secondaryOptions3;

    validInputs = true;
    disableSourceOrgInput;
    disableObjectInput;

    _communicationId = DATATEMPLATE_COMMUNICATION_ID;
    _alertId = RECORD_MATCHING_FORMULA_ID;

    @api showRecordMatchingFormula() {
        this.template.querySelector('c-copadocore-modal').show();
    }
    get isEditAndCredAccess() {
        return this.hasCredentialAccess && this.isEditMode;
    }
    get isEditMode() {
        return this.recordId ? true : false;
    }
    get disableInputs() {
        return !this.hasCredentialAccess || !this.validCredential;
    }

    get displayLink() {
        return this.readOnlyMode && this.recordId;
    }

    get disablesecondaryOptions1() {
        return (!this.selectedField1Secondary && !this.secondaryOptions1) || this.disableInputs;
    }

    get disablesecondaryOptions2() {
        return (!this.selectedField2Secondary && !this.secondaryOptions2) || this.disableInputs;
    }

    get disablesecondaryOptions3() {
        return (!this.selectedField3Secondary && !this.secondaryOptions3) || this.disableInputs;
    }

    get sourceOrg() {
        return this.recordMatchingFormula
            ? this.recordMatchingFormula[this.schema.CONFIGURATION_SOURCE_ORG.fieldApiName]
            : this.dataTemplate
            ? this.dataTemplate[this.schema.SCHEMA_CREDENTIAL.fieldApiName]
            : '';
    }

    get mainObjectDisplayValue(){
        if(!this.maiObjectLabel && this.recordMatchingFormula) {
            let fieldLabels = this.recordMatchingFormula[this.schema.FIELD_LABELS.fieldApiName] ? JSON.parse(this.recordMatchingFormula[this.schema.FIELD_LABELS.fieldApiName]) : {};
            return fieldLabels.mainObjectLabel ? fieldLabels.mainObjectLabel : this.selectedMainObject;
        }
        return `${this.maiObjectLabel} (${this.selectedMainObject})`
    }

    async connectedCallback() {
        try {
            this.showSpinner = true;
            await this._fetchDataTemplate();
            await this._fetchRecodMatchingFormula();
            await this._checkCredentialAccess();
            if (this.hasCredentialAccess) {
                let result = await validateCredential(this.sourceOrg);
                this.validCredential = result[0] && result[0].validationType === 'OK' ? true : false;
                if (!this.validCredential) {
                    const alertMessage = labels.RECORD_MATCHING_AUTH_ERROR;
                    this._publishOnMessageChannel(undefined, undefined, 'remove');
                    this._publishOnMessageChannel(alertMessage, 'error', 'add');
                }
            }
            if (this.hasCredentialAccess && this.validCredential) {
                // Note : There are two types of information required. One is related to 'mainobejct', the object on which record matching formula is built.
                // and other is any information realted to parent objects. passing mainobject to loadfields will ensure fetch data related to main object.
                await this._loadFields('mainobject');
                this.mainObjectFields = prepareFieldsForCombobox([...this._mainObjectOriginalFields]);
                await this._processRecordToDisplay();
            } else {
                this._processFieldsForReadonlyMode();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async handleClickCancel(event) {
        this._closeModal();
        this._clearValues();
        await this._processRecordToDisplay();
    }

    async handleModalClose(event) {
        this._clearValues();
        await this._processRecordToDisplay();
    }

    _closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    async handleClickSave(event) {
        try {
            this.showSpinner = true;
            this.validInputs = this._validateInputs();
            if (this.validInputs) {
                // combine data select + secondary
                const fieldsToSave = this._prepareFieldsToSave();
                await this._saveRecordMatchingFormula(fieldsToSave);
            } else {
                this._openErrorPopOver();
                this._displayErrorForRequiredField();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    handleClickRecordMatchingFormula(event) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.schema.RECORD_MATCHING_FORMULA.objectApiName,
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_blank');
        });
    }

    handleHashChange(event) {
        this.hashFormula = event.target.value;
    }

    async handleChangeField(event) {
        try {
            this.showSpinner = true;
            const id = event.target.dataset.id;
            const value = event.detail.value;
            if (id.includes('secondary')) {
                this._updateSecondarySelectedField(id, value);
            } else {
                this._updateSelectedField(id, value);
                await this._fetchSecondaryFields(id, value);
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    async _fetchSecondaryFields(id, value) {
        const referenceObject = this._referenceObjectInfo(value);
        if (referenceObject) {
            await this._loadFields(referenceObject);
            // generate picklist field and populate in perticular secondary selectoptions.
            const secondaryOptions = prepareFieldsForCombobox([...this._otherObjectOriginalFields]);
            this._updateSecondaryOptions(id, secondaryOptions);
        }
    }

    _referenceObjectInfo(field) {
        let referenceObject;
        const fieldDetail = this._mainObjectOriginalFields
            ? this._mainObjectOriginalFields.find((objectField) => objectField.name === field && objectField.type === 'reference')
            : '';
        if (fieldDetail) {
            referenceObject = fieldDetail.referenceTo[0];
        }
        return referenceObject;
    }

    async _loadFields(objectType) {
        const object = objectType === 'mainobject' ? this.selectedMainObject : objectType;
        let result = await getObjectFields({ orgId: this.sourceOrg, mainObject: object });
        result = JSON.parse(result);
        if (objectType === 'mainobject') {
            this._mainObjectOriginalFields = [...result.fields];
            this.maiObjectLabel = result.label;
        } else {
            this._otherObjectOriginalFields = [...result.fields];
        }
    }

    _validateInputs() {
        return this.sourceOrg && this.selectedMainObject && this.selectedField1 ? true : false;
    }

    _openErrorPopOver() {
        const popover = this.template.querySelector('c-copadocore-error-popover');
        if (popover) {
            popover.openPopOver();
        }
    }

    _displayErrorForRequiredField() {
        if (!this.selectedField1) {
            this.template.querySelector('[data-id="field1"]').reportValidity();
        }
    }

    _truncateString(str,limit) {
        let newString = str.slice(-limit);
        return newString; 
    }

    async _processRecordToDisplay() {
        if (this.recordId) {
            // hash external Id
            this.hashFormula = this.recordMatchingFormula[this.schema.HASH_FORMULA.fieldApiName];
            // first field
            this._processFieldsToDisplay(this.recordMatchingFormula[this.schema.FIELD1.fieldApiName], 'field1', 'secondaryField1');
            // second field
            this._processFieldsToDisplay(this.recordMatchingFormula[this.schema.FIELD2.fieldApiName], 'field2', 'secondaryField2');
            // third field
            this._processFieldsToDisplay(this.recordMatchingFormula[this.schema.FIELD3.fieldApiName], 'field3', 'secondaryField3');
        }
    }

    async _processFieldsToDisplay(field, fieldId, secondaryFieldId) {
        // call adjust field reference
        const fields = adjustFieldsWithReference(field);
        this._updateSelectedField(fieldId, fields.primary);
        // fetch secondary fields
        await this._fetchSecondaryFields(fieldId, fields.primary);
        this._updateSecondarySelectedField(secondaryFieldId, fields.secondary);
    }

    _prepareFieldsToSave() {
        const fields = {};
        const MAX_LENGTH = 80;
        fields[this.schema.RECORD_ID.fieldApiName] = this.recordId;
        if(!this.isEditMode){
            fields[this.schema.RECORD_NAME.fieldApiName] = this._truncateString(`(${this.selectedMainObject}) Formula`, MAX_LENGTH);
        }
        fields[this.schema.CONFIGURATION_SOURCE_ORG.fieldApiName] = this.sourceOrg;
        fields[this.schema.OBJECT.fieldApiName] = this.selectedMainObject;
        fields[this.schema.HASH_FORMULA.fieldApiName] = this.hashFormula;
        fields[this.schema.FIELD_LABELS.fieldApiName] =  this._prepareFieldLabels();
        fields[this.schema.FIELD1.fieldApiName] =
            this._referenceObjectInfo(this.selectedField1) && this.selectedField1Secondary
                ? adjustReference(this.selectedField1, this.selectedField1Secondary)
                : this.selectedField1;
        fields[this.schema.FIELD2.fieldApiName] =
            this._referenceObjectInfo(this.selectedField2) && this.selectedField2Secondary
                ? adjustReference(this.selectedField2, this.selectedField2Secondary)
                : this.selectedField2;
        fields[this.schema.FIELD3.fieldApiName] =
            this._referenceObjectInfo(this.selectedField3) && this.selectedField3Secondary
                ? adjustReference(this.selectedField3, this.selectedField3Secondary)
                : this.selectedField3;

        return fields;
    }

    async _saveRecordMatchingFormula(fields) {
        if (this.recordId) {
            // update record matching formula
            await updateRecord({ fields });
            this.recordMatchingFormula = fields;
            showToastSuccess(this, { message: `Record Matching Formula Updated Successfully` });
        } else {
            // create record matching formula
            const result = await createRecord({ apiName: this.schema.RECORD_MATCHING_FORMULA.objectApiName, fields });
            this.recordMatchingFormula = fields;
            this.recordId = result.id;
            this.formulaName = getFieldValue(result, this.schema.RECORD_NAME); //result.fields[this.schema.RECORD_NAME.fieldApiName];
            showToastSuccess(this, { message: `Record Matching Formula Created Successfully` });
        }
        this._closeModal();
    }

    async _fetchRecodMatchingFormula() {
        const result = await getRecordMatchingFormula({ mainObject: this.selectedMainObject });
        if (result) {
            this.recordMatchingFormula = result;
            this.recordId = result[this.schema.RECORD_ID.fieldApiName];
            this.formulaName = result[this.schema.RECORD_NAME.fieldApiName];
        }
    }

    async _fetchDataTemplate() {
        const result = await getDataTemplate({ templateId: this.templateId });
        if (result) {
            this.dataTemplate = result;
            this.selectedMainObject = result[this.schema.TEMPLATE_MAIN_OBJECT.fieldApiName];
        }
    }

    async _checkCredentialAccess() {
        this.hasCredentialAccess = await checkCredentialAccess({ credential: this.sourceOrg });
    }

    _processFieldsForReadonlyMode() {
        if (this.recordId) {
            // hash external Id
            this.hashFormula = this.recordMatchingFormula[this.schema.HASH_FORMULA.fieldApiName];
            // first field
            this._processFields(this.recordMatchingFormula[this.schema.FIELD1.fieldApiName], 'field1', 'secondaryField1');
            // second field
            this._processFields(this.recordMatchingFormula[this.schema.FIELD2.fieldApiName], 'field2', 'secondaryField2');
            // third field
            this._processFields(this.recordMatchingFormula[this.schema.FIELD3.fieldApiName], 'field3', 'secondaryField3');
            this._generatemainObjectFieldsOptions();
        }
    }

    _processFields(field, fieldId, secondaryFieldId) {
        const fields = adjustFieldsWithReference(field);
        this._updateSelectedField(fieldId, fields.primary);
        this._generateSecondaryOptions(fields.secondary, secondaryFieldId);
        this._updateSecondarySelectedField(secondaryFieldId, fields.secondary);
    }

    _generatemainObjectFieldsOptions() {
        this.mainObjectFields = [];
        if(this.selectedField1){
            this.mainObjectFields = [...this.mainObjectFields, { label: this.selectedField1, value: this.selectedField1 }];
        }
        if(this.selectedField2){
            this.mainObjectFields = [...this.mainObjectFields, { label: this.selectedField2, value: this.selectedField2 }];
        }
        if(this.selectedField3){
            this.mainObjectFields = [...this.mainObjectFields, { label: this.selectedField3, value: this.selectedField3 }];
        }
    }

    _generateSecondaryOptions(secondaryField, id) {
        const options = [{ label: secondaryField, value: secondaryField }];
        switch (id) {
            case 'secondaryField1':
                this.secondaryOptions1 = options;
                break;
            case 'secondaryField2':
                this.secondaryOptions2 = options;
                break;
            case 'secondaryField3':
                this.secondaryOptions3 = options;
                break;
        }
    }

    _clearValues() {
        this.validInputs = true;
        this.hashFormula = false;
        this.selectedField1 = '';
        this.selectedField2 = '';
        this.selectedField3 = '';
        this.selectedField1Secondary = '';
        this.selectedField2Secondary = '';
        this.selectedField3Secondary = '';
        this.secondaryOptions1 = '';
        this.secondaryOptions2 = '';
        this.secondaryOptions3 = '';
    }

    _updateSecondaryOptions(id, value) {
        switch (id) {
            case 'field1':
                this.secondaryOptions1 = value;
                break;
            case 'field2':
                this.secondaryOptions2 = value;
                break;
            case 'field3':
                this.secondaryOptions3 = value;
                break;
        }
    }

    handleRemoveField(event) {
        const id = event.target.dataset.id;
        switch (id) {
            case 'deleteField1':
                this.selectedField1 = '';
                this.selectedField1Secondary = '';
                this.secondaryOptions1 = undefined;
                break;
            case 'deleteField2':
                this.selectedField2 = '';
                this.selectedField2Secondary = '';
                this.secondaryOptions2 = undefined;
                break;
            case 'deleteField3':
                this.selectedField3 = '';
                this.selectedField3Secondary = '';
                this.secondaryOptions3 = undefined;
                break;
        }
    }

    _updateSecondarySelectedField(id, value) {
        switch (id) {
            case 'secondaryField1':
                this.selectedField1Secondary = value;
                break;
            case 'secondaryField2':
                this.selectedField2Secondary = value;
                break;
            case 'secondaryField3':
                this.selectedField3Secondary = value;
                break;
        }
    }

    _updateSelectedField(id, value) {
        switch (id) {
            case 'field1':
                this.selectedField1 = value;
                this.selectedField1Secondary = '';
                this.secondaryOptions1 = undefined;
                break;
            case 'field2':
                this.selectedField2 = value;
                this.selectedField2Secondary = '';
                this.secondaryOptions2 = undefined;
                break;
            case 'field3':
                this.selectedField3 = value;
                this.selectedField3Secondary = '';
                this.secondaryOptions3 = undefined;
                break;
        }
    }

    _publishOnMessageChannel(message, type, operation) {
        const alertMessage = createAlert(message, type, false, this._communicationId, this._alertId, operation);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alertMessage);
    }

    _prepareFieldLabels(){
        this.fieldLabels = {};
        this.fieldLabels.field1 = getFieldLabelFromSelectOptions(this.selectedField1, this.mainObjectFields);
        this.fieldLabels.field2 = getFieldLabelFromSelectOptions(this.selectedField2, this.mainObjectFields);
        this.fieldLabels.field3 = getFieldLabelFromSelectOptions(this.selectedField3, this.mainObjectFields);
        this.fieldLabels.parentField1 = getFieldLabelFromSelectOptions(this.selectedField1Secondary, this.secondaryOptions1);
        this.fieldLabels.parentField2 = getFieldLabelFromSelectOptions(this.selectedField2Secondary, this.secondaryOptions2);
        this.fieldLabels.parentField3 = getFieldLabelFromSelectOptions(this.selectedField3Secondary, this.secondaryOptions3);
        this.fieldLabels.mainObjectLabel = this.mainObjectDisplayValue;
        return JSON.stringify(this.fieldLabels);
    }    
}