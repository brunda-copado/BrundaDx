import { LightningElement, api } from 'lwc';

export default class ExpandableSection extends LightningElement {
    @api id;
    @api label;
    @api nonCollapsible = false;
    @api
    get collapsed() {
        return this._collapsed;
    }
    set collapsed(value) {
        this._collapsed = value;
    }
    _collapsed;

    get statusClass() {
        return 'slds-section ' + (this._collapsed ? '' : 'slds-is-open');
    }

    get collapsibleClass() {
        return 'slds-section__title ' + (this.collapsible ? '' : 'slds-theme_shade');
    }

    get collapsible() {
        return !this.nonCollapsible;
    }

    toggleSection() {
        this._collapsed = !this._collapsed;
    }
}