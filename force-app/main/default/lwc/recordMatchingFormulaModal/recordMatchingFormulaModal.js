import { LightningElement, api, track, wire } from 'lwc';
import { labels, schema } from './constants';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { prepareFieldsForCombobox, adjustFieldsWithReference, adjustReference, getFieldLabelFromSelectOptions } from './utils';

import getObjectFields from '@salesforce/apex/DataTemplateRecordMatchingFormulaCtrl.getObjectFields';
import getRecordMatchingFormula from '@salesforce/apex/RecordMatchingFormulaCtrl.getRecordMatchingFormula';
import checkObjectAlreadyInUse from '@salesforce/apex/RecordMatchingFormulaCtrl.checkObjectAlreadyInUse';
import fetchObjects from '@salesforce/apex/DataTemplateDefineDataSourceCtrl.fetchObjects';

import { updateRecord } from 'lightning/uiRecordApi';
export default class DataTemplateRecordMatchingFormula extends LightningElement{

    @api recordId;
    @api operation; //create, edit

    @track
    mainObjectFields;

    labels = labels;
    schema = schema;

    showSpinner = false;

    recordMatchingFormula;
    
    objectTaken;
    hashFormula;
    sourceOrg;

    selectedMainObject;
    mainObjectLabel;

    _mainObjectOriginalFields;
    _otherObjectOriginalFields;
    
    fieldLabels
    
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
    disableSave = true;

    objectErrors = [];
    objectOptions =[];

    @api showRecordMatchingFormula() {
        this.template.querySelector('c-copadocore-modal').show();
        this.loadData();
    }

    get displayLookup(){
        return this.operation === 'create';
    }

    get displayEditInfo(){
        return this.operation === 'edit';
    }

    get hideSecondaryOptions1() {
        return (!this.selectedField1Secondary && !this.secondaryOptions1);
    }

    get hideSecondaryOptions2() {
        return (!this.selectedField2Secondary && !this.secondaryOptions2);
    }

    get hideSecondaryOptions3() {
        return (!this.selectedField3Secondary && !this.secondaryOptions3);
    }

    get mainObjectDisplayValue(){
        return `${this.mainObjectLabel} (${this.selectedMainObject})`;
    }

    async loadData(){
        try {
            this.showSpinner = true;
            await this._fetchRecodMatchingFormula();
            if(!this.selectedMainObject){
                this.objectOptions = await fetchObjects({ orgId: this.sourceOrg });
                this._initLookupDefaultResults();
            }
            else{
                await this._loadFields('mainobject');
                this.mainObjectFields = prepareFieldsForCombobox([...this._mainObjectOriginalFields]);
                await this._processRecordToDisplay();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
            this.disableSave = false;
        }
        
    }

    async handleClickCancel(event) {
        this._closeModal();
        this._clearValues();
    }

    async handleModalClose(event) {
        this._clearValues();
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
                this._displayErrorForLookUp();
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

    async handleChangeMainObject(event) {
        this.selectedMainObject = event.detail.length > 0 ? event.detail[0] : null;
        this.objectTaken = false;
        this._clearValues();
        this.disableSave = false;
        if (this.selectedMainObject) {
            this.showSpinner = true
            this.objectErrors = [];
            const result = await checkObjectAlreadyInUse({ objectName : this.selectedMainObject});
            if(result){
                this.objectTaken = true;
                this.showSpinner = false;
                return ;
            }
            await this._loadFields('mainobject');
            this.mainObjectFields = prepareFieldsForCombobox([...this._mainObjectOriginalFields]);
            this.showSpinner = false;
        }
    }


    handleHashChange(event) {
        this.hashFormula = event.target.value;
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
            this.mainObjectLabel = result.label;
        } else {
            this._otherObjectOriginalFields = [...result.fields];
        }
    }

    _validateInputs() {
        return this.selectedMainObject && this.selectedField1 ;
    }

    _displayErrorForLookUp() {
        if (!this.selectedMainObject) {
            this.objectErrors = [{ id: labels.COMPLETE_THIS_FIELD, message: labels.COMPLETE_THIS_FIELD }];
        }
    }

    _closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
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

    async _processRecordToDisplay() {
        if (this.recordId) {
            this.hashFormula = this.recordMatchingFormula[this.schema.HASH_FORMULA.fieldApiName];
            await this._processFieldsToDisplay(this.recordMatchingFormula[this.schema.FIELD1.fieldApiName], 'field1', 'secondaryField1');
            await this._processFieldsToDisplay(this.recordMatchingFormula[this.schema.FIELD2.fieldApiName], 'field2', 'secondaryField2');
            await this._processFieldsToDisplay(this.recordMatchingFormula[this.schema.FIELD3.fieldApiName], 'field3', 'secondaryField3');
        }
    }

    async _processFieldsToDisplay(field, fieldId, secondaryFieldId) {
        const fields = adjustFieldsWithReference(field);
        this._updateSelectedField(fieldId, fields.primary);
        await this._fetchSecondaryFields(fieldId, fields.primary);
        this._updateSecondarySelectedField(secondaryFieldId, fields.secondary);
    }

    _prepareFieldsToSave() {
        const fields = {};
        fields[this.schema.RECORD_ID.fieldApiName] = this.recordId;
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
            await updateRecord({ fields });
            this.recordMatchingFormula = fields;
            showToastSuccess(this, { message: labels.UPDATE_SUCCESSFUL });
            this._closeModal();
            this._clearValues();
    }

    async _fetchRecodMatchingFormula() {
        const result = await getRecordMatchingFormula({ recordId: this.recordId });
        if (result) {
            this.recordMatchingFormula = result;
            this.selectedMainObject = result[this.schema.OBJECT.fieldApiName]
            this.formulaName = result[this.schema.RECORD_NAME.fieldApiName];
            this.sourceOrg = result[this.schema.CONFIGURATION_SOURCE_ORG.fieldApiName]
        }
    }

    _generatemainObjectFieldsOptions() {
        this.mainObjectFields = [
            { label: this.selectedField1, value: this.selectedField1 },
            { label: this.selectedField2, value: this.selectedField2 },
            { label: this.selectedField3, value: this.selectedField3 }
        ];
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
        this.objectTaken = false;
        this.disableSave = true;
        this.mainObjectFields = [];
        this.objectErrors=[];
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

    _initLookupDefaultResults() {
        const lookup = this.template.querySelector('c-lookup');
        if (lookup) {
            lookup.setDefaultResults(this.objectOptions.map((option) => ({ id: option.value, title: option.label })));
        }
    }

}