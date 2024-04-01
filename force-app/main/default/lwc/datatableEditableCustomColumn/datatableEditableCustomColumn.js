import { LightningElement, api } from 'lwc';
import { formatLabel } from 'c/copadocoreUtils';

import { label } from './constants';

export default class DatatableEditableCustomColumn extends LightningElement {
    label = label;

    @api rowId;
    @api property;
    @api value;
    @api readOnlyMode;
    @api selectedCount;

    get updateSelected() {
        return Array.from(this.template.querySelectorAll('[data-element="update-selected-checkbox"]')).some((element) => element.checked);
    }

    get updateSelectedItemsLabel() {
        const formattingArguments = [this.selectedCount];
        return formatLabel(label.UPDATE_SELECTED_ITEMS, formattingArguments);
    }

    get multiEdit() {
        return this.selectedCount > 1;
    }

    get cellStyle() {
        return this.multiEdit && !this.readOnlyMode ? 'position: absolute; top: 0; padding: 0; margin: 0;' : '';
    }

    handleClickEdit() {
        this.dispatchEvent(
            new CustomEvent('editcolumn', {
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

    handleClickCancel() {
        this.dispatchEvent(
            new CustomEvent('cancelmultiedit', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {}
            })
        );
    }

    handleClickApply() {
        this.dispatchEvent(
            new CustomEvent('applymultiedit', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    rowId: this.rowId,
                    property: this.property,
                    updateSelected: this.updateSelected
                }
            })
        );
    }
}