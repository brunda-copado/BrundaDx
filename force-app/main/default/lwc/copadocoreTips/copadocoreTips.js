import { LightningElement, api } from 'lwc';

export default class CopadoDataSetTips extends LightningElement {
    @api title;
    @api tip1;
    @api tip2;
    @api tip3;
    @api tip4;

    tips;

    connectedCallback() {
        this.tips = [this.tip1, this.tip2, this.tip3, this.tip4];
    }
}