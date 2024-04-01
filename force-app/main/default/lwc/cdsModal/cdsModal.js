import { LightningElement, api } from 'lwc';

export default class CdsModal extends LightningElement {
    @api iconName;
    @api iconSize = 'small';
    @api hideClose;
    @api hasOverflow;
    @api size = 'x-small';

    async renderedCallback() {
        this.dispatchEvent(new CustomEvent('modalrendered'));
    }

    get modalClasses() {
        return `slds-modal slds-fade-in-open slds-modal_${this.size}`;
    }

    get contentModalClasses() {
        return this.hasOverflow ? 'cds-modal-content overflow' : 'cds-modal-content';
    }

    showModal = false;
    @api show() {
        this.showModal = true;
    }
    @api hide() {
        this.showModal = false;
    }

    handleClose() {
        this.hide();
        this.dispatchEvent(new CustomEvent('modalclose'));
    }

    showTitleContainer() {
        // const titleContainer = this.template.querySelector('[data-id="titleContainer"]');
        // titleContainer.classList.remove('slds-hide');
    }

    handleTitleChange() {
        // if (this.showModal) {
        //     this.showTitleContainer();
        //     const title = this.template.querySelector('[data-id="title"]');
        //     title.classList.remove('slds-hide');
        // }
    }

    handleTaglineChange() {
        // if (this.showModal) {
        //     this.showTitleContainer();
        //     const tagline = this.template.querySelector('[data-id="tagline"]');
        //     tagline.classList.remove('slds-hide');
        // }
    }

    handleFooterChange() {
        // if (this.showModal) {
        //     const footer = this.template.querySelector('[data-id="footer"]');
        //     footer.classList.remove('slds-hide');
        // }
    }
}