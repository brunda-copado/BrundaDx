import { LightningElement, api, wire } from 'lwc';
import { reduceErrors , namespace } from 'c/copadocoreUtils';
import { label , columns} from './constants';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { showToastSuccess , showToastError} from 'c/copadocoreToastNotification';
import { getSearchedData, getSortedData } from 'c/datatableService';

import fetchRows from '@salesforce/apex/EnvironmentVarPipelineRelatedListCtrl.fetchRows';
import onSave from '@salesforce/apex/EnvironmentVarPipelineRelatedListCtrl.onSave';

const MINIMUM_SEARCH_TERM_LENGTH = 3;
export default class ManageEnvironmentVariablePopup extends LightningElement {

    @api record;
    @api parentId;
    @api sObjectName;

    @wire(MessageContext)
    messageContext;

    value = 'allMetadata';
    columns = columns;
    label = label;
    isSpecificMetadata = false;
    showSpinner = false;
    allRows = [];
    _allRowsUpdt = new Set();
    _allRowsClone = [];
    data=[];
    isEditMode = false;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    validationResult;
    variableName = '';
    metadataType = '';
    defaultValue = '';
    draftValues = [];
    searchValue = '';

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    handleCancel() {
        this.hide();
    }

    get title() {
        if(this.record){
            this.isEditMode = true;
            return `${label.EDIT} ${label.ENVIRONMENT_VAR}`;
        }else{
            return `${label.NEW} ${label.ENVIRONMENT_VAR}`;
        }
    }

    get options() {
        return [
            { label: label.Apply_all_Metadata , value: 'allMetadata' },
            { label: label.Specific_Metadata , value: 'specificMetadata' },
        ];
    }

    get showErrorPopover() {
        return this.validationResult && this.validationResult.message.length > 0;
    }

    get errorPopoverMessage() {
        return this.validationResult.message;
    }

    get isEnvironment(){
        return `${this.sObjectName}` == (namespace ? namespace+'Environment__c' : 'Environment__c');
    }

    @api async setDataTable() {
        this.showSpinner = true;
        this.setVariableData();
        await this._getRowsData();
        this.showSpinner = false;
    }

    setVariableData(){
        this.reset();
        if(this.record){
            let record = this.record;
            this.variableName = record.Name;
            let scope = namespace ? record[namespace + "Scope__c"] : record.Scope__c;
            if(scope){
                this.metadataType = scope;
                this.isSpecificMetadata = true;
                this.value = 'specificMetadata';
            }
        }
    }

    handleScopeChange(event){
        const selectedOption = event.detail.value;
        if(selectedOption === 'specificMetadata'){
            this.isSpecificMetadata = true;
        }else{
            this.isSpecificMetadata = false;
        }
    }

    handleVariableChange(event){
        this.variableName = event.detail.value;
    }

    handleMetadataChange(event){
        this.metadataType = event.detail.value;
    }

    async _getRowsData() {
        let rows;
        try {
            rows = await fetchRows({ environmentVar: this.record ,parentId: this.parentId, sObjectName: this.sObjectName});
            this.allRows = rows;
            this._allRowsClone = rows;
            this.allRows.forEach( row => {
                if(row.value != '') {
                    this._allRowsUpdt.add(row.environmentId+'-'+row.value);
                }
            });
        } catch (error) {
            this.messageAlert(label.Fetch_Data_Error + ' ' + reduceErrors(error), 'error', true);
        }
        return rows;
    }

    messageAlert(message, variant, dismissible) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId: this.communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    cellValueChange(event){
        let rowId = event.detail.draftValues[0].id;
        let addElement = false;
        const data = rowId.split('-');
        let index = data[1];
        let rows = JSON.parse(JSON.stringify(this.allRows));
        rows[index].value = event.detail.draftValues[0].value;
        this.allRows = rows;
        if(this._allRowsUpdt.size != 0 ) {
            this._allRowsUpdt.forEach(element => {
                if(element.split('-')[0] === rows[index].environmentId) {
                    this._allRowsUpdt.delete(element);
                    addElement = true;
                }
                else {
                    this._allRowsUpdt.add(rows[index].environmentId+'-'+rows[index].value);
                }
            });
        }
        else {
            this._allRowsUpdt.add(rows[index].environmentId+'-'+rows[index].value);
        }
        if(addElement) {
            this._allRowsUpdt.add(rows[index].environmentId+'-'+rows[index].value);
        }
    }

    handleSave(){
        
        this.validationResult = this._validateEnvironmentVariable();    
        if(this.validationResult.message.length > 0){
            this.template.querySelector('c-copadocore-error-popover')?.openPopOver();
        }else{
            this._save();
            this._allRowsUpdt.clear();
        }
    }

    _validateEnvironmentVariable(){
        let message = [];
        let isEmptyValue = false;
        this.tempData = JSON.parse(JSON.stringify(this._allRowsClone))

        this.tempData.forEach( row => {
            this._allRowsUpdt.forEach( element => {
                if(row.environmentId === element.split('-')[0]) {
                    row.value = element.split(/-(.*)/)[1];
                    }
            });
        });
        
        const valueExists = (element) => element.value === '';
        isEmptyValue = this.tempData.some(valueExists);

        if(!this.variableName){
            message.push(label.VARIABLE_NAME_REQUIRED);
        }       
        if(isEmptyValue){
            message.push(label.ENVIRONMENT_VAR_VALUE_EMPTY); 
        }
        if(this.isSpecificMetadata && !this.metadataType){
            message.push(label.DEFINE_METADATA_EMPTY);
        } 
        if((this.sObjectName == (namespace ? namespace+'Environment__c' : 'Environment__c')) && this.variableName != this.record.Name){
            message.push(label.EnvVar_Name_Update_Error);
        }    
        return {
            message
        };
    }

    _saveUserInput(pData) {
        this._allRowsUpdt.forEach(element => {
            pData.forEach(row => {
                if(element.split('-')[0] === row.environmentId) {
                    row.value = element.split('-')[1];
                }
            });
        });
        this.draftValues = [];
    }

    async _save(){
        try {
            let scopeValue = this.metadataType;
            if(!this.isSpecificMetadata){
                scopeValue = '';
            }
            this.tempData = JSON.parse(JSON.stringify(this._allRowsClone))

            this.tempData.forEach( row => {
                this._allRowsUpdt.forEach( element => {
                    if(row.environmentId === element.split('-')[0]) {
                        row.value = element.split(/-(.*)/s)[1];
                    }
                });
            });
            const environment = {
                variableName: this.variableName,
                scope: scopeValue,
                environmentValue: this.tempData
            };
            this.showSpinner = true;
            const result = await onSave({ environmentVar: JSON.stringify(environment), isEdit: this.isEditMode });
            if (result !== undefined) {
                showToastSuccess(this, {
                    title: label.Records_Updated_Successfully
                });
            }
            this.showSpinner = false;
            this.dispatchEvent(new CustomEvent('savelicenses'));
            this.hide();         
        } catch (error) {
            this.showSpinner = false;
            showToastError(this, { message: error.body.message });
        }
    }

    handleDefaultValue(event){
        this.defaultValue = event.detail.value;
    }

    handleApply(){
        let defaultValue = this.defaultValue;

        if(this._allRowsClone){
            let rows = JSON.parse(JSON.stringify(this._allRowsClone));
            this.draftValues = [];
            rows.forEach(row =>{
                if(defaultValue.includes('{!EnvName}')){
                    row.value = defaultValue.replace('{!EnvName}', row.environment.replaceAll(' ','').toLocaleLowerCase());
                }else{
                    row.value = defaultValue;
                }            
            });
            this.allRows = rows;
            this._allRowsClone = rows;
        }
    }

    handleSort(event) {
        try {
            this.showSpinner = true;
            this.sortDirection = event.detail.sortDirection;
            this.sortedBy = event.detail.fieldName;
            const cloneData = [...this.allRows];
            const sortedData = this._applySort(cloneData, { name: this.sortedBy, sortDirection: this.sortDirection });
            this.allRows = sortedData;
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } finally {
            this.showSpinner = false;
        }
    }

    _applySort(rows, sortConfiguration) {
        return rows && rows.length ? getSortedData(this.columns, rows, sortConfiguration) : rows;
    }

    handleSearch(event) {
        const searchTerm = event.target.value;
        const hasNoSearchTerm = !searchTerm || searchTerm === '' || searchTerm.trim() === '';
        if (hasNoSearchTerm) {
            this._clearSearch();
        } else {
            this.searchValue = searchTerm.trim();
            this._applySearch();
        }
    }

    async _applySearch() {
        this.data = [];
        if (this.searchValue.length < MINIMUM_SEARCH_TERM_LENGTH) {
            return;
        } else {
            try {
                const filteredRawData = await getSearchedData(this.columns, this.allRows, this.searchValue);
                if (filteredRawData) {
                    this.data = [...filteredRawData];
                    this._saveUserInput(this.data);
                    this.allRows = this.data;
                }
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        }
    }

    handleClearSearch(event){
        const searchTerm = event.detail.value;
        const hasNoSearchTerm = !searchTerm || searchTerm === '' || searchTerm.trim() === '';
        if (hasNoSearchTerm) {
            this._clearSearch();
        }
    }

    _clearSearch() {
        this.tempData = JSON.parse(JSON.stringify(this._allRowsClone));
        this.searchTerm = '';
        this.data = [];
        this._saveUserInput(this.tempData);
        this.draftValues = [];
        this.allRows = this.tempData;
    }
    
    reset(){
        this.variableName = '';
        this.isEditMode = false;
        this.validationResult = null;
        this.isSpecificMetadata = false;
        this.defaultValue = '';
        this.searchTerm = '';
        this.searchValue = '';
        this.metadataType = '';
        this.value = 'allMetadata';
        this._allRowsUpdt.clear();
    }
}