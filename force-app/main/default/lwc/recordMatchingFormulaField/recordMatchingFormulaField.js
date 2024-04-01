import { LightningElement, api } from 'lwc';

export default class RecordMatchingFormulaField extends LightningElement {

    @api label;
    @api value;
    @api helpText;
}