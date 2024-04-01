import { LightningElement, api, wire} from 'lwc';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { separatedFieldValue } from './utils';
import { schema, labels } from './constants';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

export default class RecordMatchingFormulaDetail extends LightningElement {

    @api recordId;
    @api credentialValid;

    labels = labels;
    schema = schema;
    formulaDetail;
    fieldLabels;
    fieldsInfo;
    
    @wire(getObjectInfo, { objectApiName: schema.RECORD_MATCHING_FORMULA })
    getRecordMatchingInfo({error, data}) {
        if (data){
            this.fieldsInfo = data.fields;
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }   

    }

    @wire(getRecord, { recordId: '$recordId', fields: [schema.OBJECT, schema.FIELD1, schema.FIELD2, schema.FIELD3, schema.HASH_FORMULA, schema.FIELD_LABELS] })
    wiredRecord({ error, data }) {
        if (data) {
            this.formulaDetail = data
            this.fieldLabels = getFieldValue(data, schema.FIELD_LABELS) ? JSON.parse(getFieldValue(data, schema.FIELD_LABELS)) : {};
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        } 
    }

    get disableEdit(){
        return !this.credentialValid;
    }

    get objectHelpText(){
        return this.fieldsInfo ? this.fieldsInfo[schema.OBJECT.fieldApiName].inlineHelpText : '';
    }

    get objectValue(){
        return this.fieldLabels && this.fieldLabels.mainObjectLabel ? this.fieldLabels.mainObjectLabel : this.formulaDetail ? getFieldValue( this.formulaDetail, schema.OBJECT) : '' ; 
    }

    get hashIdValue(){
        return this.formulaDetail ? getFieldValue( this.formulaDetail, schema.HASH_FORMULA) : '';
    }

    get field1Value(){
        return this.fieldLabels &&  this.fieldLabels.field1 ? this.fieldLabels.field1 : this.formulaDetail ? separatedFieldValue(getFieldValue( this.formulaDetail, schema.FIELD1)) : '' ;    
    }

    get field2Value(){
        return this.fieldLabels &&  this.fieldLabels.field2 ? this.fieldLabels.field2 : this.formulaDetail ? separatedFieldValue(getFieldValue( this.formulaDetail, schema.FIELD2)) : '' ;
    }

    get field3Value(){
        return this.fieldLabels &&  this.fieldLabels.field3 ? this.fieldLabels.field3 : this.formulaDetail ? separatedFieldValue(getFieldValue( this.formulaDetail, schema.FIELD3)) : '' ;
    }

    get parentField1(){  
        return this.fieldLabels &&  this.fieldLabels.parentField1 ? this.fieldLabels.parentField1 : this.formulaDetail ? separatedFieldValue(getFieldValue( this.formulaDetail, schema.FIELD1),true) : '' ;
    }

    get parentField2(){
        return this.fieldLabels &&  this.fieldLabels.parentField2 ? this.fieldLabels.parentField2 : this.formulaDetail ? separatedFieldValue(getFieldValue( this.formulaDetail, schema.FIELD2), true) : '' ;
    }

    get parentField3(){
        return this.fieldLabels &&  this.fieldLabels.parentField3 ? this.fieldLabels.parentField3 : this.formulaDetail ? separatedFieldValue(getFieldValue( this.formulaDetail, schema.FIELD3), true) : '' ;
    }

    handleEditClick(event){
        this._dispatchEditFormulaEvent();
    }

    _dispatchEditFormulaEvent(){
        this.dispatchEvent(new CustomEvent('editformula'));
    }

}