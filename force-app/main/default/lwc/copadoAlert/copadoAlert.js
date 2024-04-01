import { LightningElement, api } from 'lwc';
import { getTheme, getIconName } from './utils';

export default class CopadoAlert extends LightningElement {
    @api message;
    @api variant;
    @api dismissible = false;
    showAlert = true;

    get styleClasses() {
        return `slds-notify slds-notify_alert ${getTheme(this.variant)}`;
    }

    get iconName() {
        return getIconName(this.variant);
    }

    // PUBLIC

    handleCloseAlert() {
        this.showAlert = false;
        this.dispatchEvent(new CustomEvent('closealert'));
    }
}