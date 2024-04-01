import { LightningElement, api, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import { namespace, reduceErrors} from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import HIDE_LIGHTNING_HEADER from '@salesforce/resourceUrl/HideLightningHeader';
import CUSTOM_HIGHLIGHT_PANEL from '@salesforce/resourceUrl/customHighlightPanel';
import getFieldSet from '@salesforce/apex/CustomHighlightPanelController.getFieldList';
import getObjectPluralName from '@salesforce/apex/CustomHighlightPanelController.getObjectPluralName';
import getRecordTypeName from '@salesforce/apex/CustomHighlightPanelController.getRecordTypeName';
import RECORDTYPE from '@salesforce/label/c.Record_Type';

export default class CustomHighlightPanel extends NavigationMixin(LightningElement) {
    @api iconName;
    @api title;
    @api variant = 'record'; // Note: possible values -> record, related
    @api fieldSetName ='';  //If fieldSet exist for SObject else Fields will be display from Compact layout

    get relatedList() {
        return this.variant === 'related';
    }

    get recordHome() {
        return this.variant === 'record';
    }

    get useFieldSet(){
        return !!this.fieldSetName;
    }

    recordName;
    sobjectType;
    recordId;
    parentTitle;
    formFields;
    recordTypeName;
    label = {RECORDTYPE};

    
    @wire(CurrentPageReference)
    getParameters(pageReference) {
        if (pageReference && pageReference.state) {
            const parameterName = `${namespace || 'c__'}recordId`;
            this.recordId = pageReference.state[parameterName];
        }
    }

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Compact'], modes: ['View'] })
    wiredRecord({ error, data }) {
        if (data) {
            this.sobjectType = data.apiName;
            this.recordName = data.fields.Name ? data.fields.Name.value : '';
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    @wire(getRecordTypeName, {recordId: '$recordId'})
    wiredRecordTypeName({ error, data }) {
        if (data) {
            this.recordTypeName = data;
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });   
        }
    }

    @wire(getFieldSet, {recordId: '$recordId', fieldSetName: '$fieldSetName'})
    wiredFieldSet({ error, data }) {
        if (data) {
            this.formFields = data.map(fieldDefinition => { return { apiFieldName: fieldDefinition.apiFieldName, isRecordType: fieldDefinition.apiFieldName.includes('RecordTypeId')}});        
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });   
        }
    }

    @wire(getObjectPluralName, {recordId: '$recordId'})
    wiredObjectName({ error, data }) {
        if (data) {
            this.parentTitle = data;
        } else if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });   
        }
    }


    // TEMPLATE

    connectedCallback() {
        loadStyle(this, HIDE_LIGHTNING_HEADER);
        loadStyle(this, CUSTOM_HIGHLIGHT_PANEL);
    }

    handleClickRecordName() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    handleClickParentTitle() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.sobjectType,
                actionName: 'list'
            },
            state: {
                filterName: 'Recent' 
            }
        });
    }
}