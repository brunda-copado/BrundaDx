import { LightningElement, api } from 'lwc';

// Utils
import { flushPromises } from 'c/copadocoreUtils';

import CloseDialog from '@salesforce/label/c.CloseDialog';

export default class CopadocoreErrorPopover extends LightningElement {
    @api title = 'Resolve error';
    @api message = '';
    @api popoverPosition = 'left';

    label = {
        CloseDialog
    };

    displayPopover;
    sectionClass = 'slds-popover slds-popover_error slds-nubbin_bottom-left slds-is-absolute';

    connectedCallback() {
        setTimeout(() => {
            this.openPopOver();
        }, 100);
    }

    get messageTypeString() {
        return typeof this.message === 'string';
    }

    get messageTypeList() {

        return typeof this.message === 'object';
    }


    @api
    async openPopOver() {
        if (!this.displayPopover) {
            this.displayPopover = true;
            await flushPromises();
        }

        const errorButtonElement = this.template.querySelector('button[id*="error-button"]');
        const popOverElement = this.template.querySelector('section[id*="popover-section"]');
        if (popOverElement) {
            popOverElement.style.display = 'inline';
            popOverElement.style.bottom = `${errorButtonElement.getBoundingClientRect().height + 10}px`;
            if (this.popoverPosition === 'right') {
                popOverElement.style.right = `-${errorButtonElement.getBoundingClientRect().width / 2}px`;
                this.sectionClass = 'slds-popover slds-popover_error slds-nubbin_bottom-right slds-is-absolute';
            } else {
                popOverElement.style.left = `-${errorButtonElement.getBoundingClientRect().width / 2}px`;
            }

        }
    }

    closePopOver() {
        this.displayPopover = false;
    }

    async togglePopOver() {
        this.displayPopover = !this.displayPopover;

        await flushPromises();

        if (this.displayPopover) {
            this.openPopOver();
        }
    }
}