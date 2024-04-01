import { LightningElement, api } from 'lwc';

export default class UserStoryCommitOperationColumn extends LightningElement {
    property = 'Operation';
    @api rowId;
    @api readOnlyMode;
    @api selectedCount;
    @api options;

    @api
    get operation() {
        return this._operation;
    }
    set operation(value) {
        this._operation = value;
        this.value = value;
    }
    _operation;

    value;

    get multiEdit() {
        return this.selectedCount > 1;
    }

    // TEMPLATE

    handleChangeOption(event) {
        this.value = event.detail.value;
        if (!this.multiEdit) {
            this.dispatchEvent(
                new CustomEvent('changedraftvalue', {
                    composed: true,
                    bubbles: true,
                    cancelable: true,
                    detail: {
                        rowId: this.rowId,
                        property: this.property,
                        value: this.value
                    }
                })
            );
        }
    }

    handleApplyMultiEdit(event) {
        const updateSelected = event.detail.updateSelected;
        this.dispatchEvent(
            new CustomEvent('changemultidraftvalue', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    rowId: this.rowId,
                    property: this.property,
                    value: this.value,
                    updateSelected: updateSelected
                }
            })
        );
    }
}