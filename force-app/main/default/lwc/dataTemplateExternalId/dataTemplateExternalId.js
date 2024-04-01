import { LightningElement, api } from 'lwc';

export default class DataTemplateExternalId extends LightningElement {
    @api useAsExternalId;
    @api readOnlyMode;
    @api fieldName;
    @api isSelected;
    @api isExternalId;

    get isVisible(){
        return this.isSelected && this.isExternalId;
    }

    handleChange(event) {
        this.dispatchEvent(
            new CustomEvent('selectexternalid', {
                bubbles: true,
                composed: true,
                detail: { useAsExternalId: event.detail.checked, fieldName: this.fieldName }
            })
        );
    }
}