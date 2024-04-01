import { api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import LightningDatatable from 'lightning/datatable';

import { fireEvent } from 'c/copadoCorePubsub';
export default class CopadocoreDatatableExtended extends LightningDatatable {
    @wire(CurrentPageReference) pageRef;

    _tableRows;
    _dragAndDropCells;

    _draggingCell;
    _draggingRow;
    _draggingBeginsAt;
    _draggingEndsAt;

    /**
     * Deprecated: can not be removed due to managed package
     */
    @api draggable;
    @api sourceName;

    get hasDraggingStarted() {
        return this._draggingCell ? true : false;
    }

    // Handler functions bound to this
    _boundHandledMouseDown = this._handleMouseDown.bind(this);
    _boundHandledMouseMove = this._handleMouseMove.bind(this);
    _boundHandledMouseUp = this._handleMouseUp.bind(this);
    _boundHandleMouseLeaveTbody = this._handleMouseLeaveTbody.bind(this);

    constructor() {
        super();
        this.template.addEventListener('mousemove', this._boundHandledMouseMove);
        this.template.addEventListener('mouseup', this._boundHandledMouseUp);
    }

    renderedCallback() {
        super.renderedCallback();
        this._setUpDragAndDrop();
    }

    _setUpDragAndDrop() {
        const tbody = this.template.querySelector('tbody');
        tbody.addEventListener('mouseleave', this._boundHandleMouseLeaveTbody);

        const tableRowsNodes = tbody.querySelectorAll('tr');
        this._tableRows = Array.from(tableRowsNodes);
        this._dragAndDropCells = tbody.querySelectorAll('tr>th:first-of-type');

        this._setDraggableCells();
    }

    _setDraggableCells() {
        this._dragAndDropCells.forEach((cell) => {
            cell.style.cursor = 'grab';
            cell.addEventListener('mousedown', this._boundHandledMouseDown);
        });
    }

    _handleMouseDown(event) {
        // To cancel default behavior: selection
        event.preventDefault();

        this._draggingCell = event.currentTarget;
        this._draggingRow = this._draggingCell.parentNode;
        this._draggingBeginsAt = this._draggingEndsAt = this._tableRows.indexOf(this._draggingRow);

        this._setStartDraggingStyles(event);
    }

    _setStartDraggingStyles() {
        this._draggingRow.classList.add('slds-theme_shade', 'slds-theme_alert-texture');

        this._tableRows.forEach((row) => {
            row.style.cursor = 'grabbing';
        });

        this._dragAndDropCells.forEach((cell) => {
            cell.style.cursor = 'grabbing';
        });
    }

    _handleMouseMove(event) {
        if (this.hasDraggingStarted) {
            const elementPassingThrough = event.target.parentNode;
            if (this._tableRows.includes(elementPassingThrough)) {
                const elementPassingThroughIndex = this._tableRows.indexOf(elementPassingThrough);
                this._draggingEndsAt = elementPassingThroughIndex;
            }
        }
    }

    _handleMouseUp() {
        if (this.hasDraggingStarted) {
            const detail = {
                draggingBeginsAt: this._draggingBeginsAt,
                draggingEndsAt: this._draggingEndsAt,
                sourceName: this.sourceName
            };

            // Can not use this.dispatchEvent due to an issue with LWC
            // extending other components aside from LightningElement
            fireEvent(this.pageRef, 'dropRowEvent', detail);
            this._clearDragAndDropInProgress();
        }
    }

    _clearDragAndDropInProgress() {
        this._draggingRow.classList.remove('slds-theme_shade', 'slds-theme_alert-texture');

        this._tableRows.forEach((row) => {
            row.style.cursor = 'default';
        });

        this._dragAndDropCells.forEach((cell) => {
            cell.style.cursor = 'grab';
        });

        this._draggingCell = undefined;
        this._draggingRow = undefined;
        this._draggingBeginsAt = undefined;
        this._draggingEndsAt = undefined;
    }

    _handleMouseLeaveTbody() {
        if (this.hasDraggingStarted) {
            this._clearDragAndDropInProgress();
        }
    }
}