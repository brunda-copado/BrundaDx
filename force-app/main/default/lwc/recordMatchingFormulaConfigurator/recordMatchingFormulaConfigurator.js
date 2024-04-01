import { LightningElement, api } from 'lwc';

import {label} from './constants'

export default class RecordMatchingFormulaConfigurator extends LightningElement {

    @api credentialValid;

    label = label;

    get disableConfigureButton(){
        return !this.credentialValid;
    }

    handleClickConfigureFormula(event){
        this.dispatchEvent(new CustomEvent('displaymodal'));
    }
}