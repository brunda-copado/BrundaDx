import { LightningElement, api } from 'lwc';

export default class DataTemplateSelectField extends LightningElement {
    @api isSelected;
    @api readOnlyMode;
    @api fieldName;

    handleChange(event) {
        this.dispatchEvent(
            new CustomEvent('selectfield', {
                bubbles: true,
                composed: true,
                detail: { isChecked: event.detail.checked, fieldName: this.fieldName }
            })
        );
    }
}