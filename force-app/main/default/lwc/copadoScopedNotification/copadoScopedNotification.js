import { LightningElement, api } from 'lwc';
import { getTheme, getIconName, getIconVariant } from './utils';

export default class CopadoScopedNotification extends LightningElement {
    @api message;
    @api variant;

    get styleClasses() {
        return `slds-scoped-notification slds-media slds-media_center slds-is-relative z-index-auto ${getTheme(this.variant)}`;
    }

    get iconName() {
        return getIconName(this.variant);
    }

    get iconVariant() {
        return getIconVariant(this.variant);
    }
}