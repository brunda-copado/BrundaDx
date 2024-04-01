import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';

import copadocoreReadModeFieldResources from '@salesforce/resourceUrl/copadocoreReadModeFieldResources';

export default class CopadocoreReadModeField extends LightningElement {
    @api label;
    @api value;

    get labelExists() {
        return this.label !== undefined && this.label !== '';
    }

    renderedCallback() {
        loadStyle(this, copadocoreReadModeFieldResources + '/copadocoreReadModeField.css');
    }

    // PUBLIC

    handleClick() {
        this.dispatchEvent(new CustomEvent('turnedit', { bubbles: true }));
    }

    handleMouseOver() {
        this._changeIconColorDark();
    }

    handleMouseOut() {
        this._changeIconColorLight();
    }

    // PRIVATE

    _changeIconColorDark() {
        const icon = this.template.querySelector('lightning-icon');
        icon.classList.remove('light-icon');
        icon.classList.add('dark-icon');
    }

    _changeIconColorLight() {
        const icon = this.template.querySelector('lightning-icon');
        icon.classList.remove('dark-icon');
        icon.classList.add('light-icon');
    }
}