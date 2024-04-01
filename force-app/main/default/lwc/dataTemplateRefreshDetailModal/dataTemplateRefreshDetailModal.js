import { LightningElement, api } from 'lwc';
import { label } from './constants';

export default class DataTemplateRefreshDetailModal extends LightningElement {
    @api refreshDetail;

    addedInfo = [];
    removedInfo = [];
    label = label;

    connectedCallback() {
        if (this.refreshDetail && this.refreshDetail.add) {
            this.addedInfo = this.refreshDetail.add;
        }

        if (this.refreshDetail && this.refreshDetail.remove) {
            this.removedInfo = this.refreshDetail.remove;
        }
    }

    handleClickClose(event) {
        this._closeModal();
        this.addedInfo = [];
        this.removedInfo = [];
        this.dispatchEvent(new CustomEvent('closerefreshmodal'));
    }

    _closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    renderedCallback() {
        if (this.addedInfo.length > 0 || this.removedInfo.length > 0) {
            this.template.querySelector('c-copadocore-modal').show();
        }
    }
}