import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { loadStyle } from 'lightning/platformResourceLoader';

import { handleAsyncError, getDebouncedFunction } from 'c/copadocoreUtils';

import relatedListResources from '@salesforce/resourceUrl/relatedListResources';
import fetchRelatedListConfig from '@salesforce/apex/RelatedListCtrl.fetchRelatedListConfig';

import { label, actions } from './constants';



// Global value that will increase for each component instance
let _numberOfCurrentInstance = 0;

export default class RelatedList extends NavigationMixin(LightningElement) {

    // Required
    @api recordId;
    @api fieldset;
    @api relatedList;

    // Optional
    @api relationshipField; // (Not used if tableInfo is provided)
    @api orderBy = 'Id ASC NULLS LAST, CreatedDate'; // (Not used if tableInfo is provided)
    @api recordSize = 6;
    @api height = 'auto';

    @api hideHeader;
    @api headerIcon;
    @api customTitle;
    @api showSubtitle;
    @api customSubtitle;
    @api hideNewAction;
    @api showSearch;
    @api hideFooter;
    @api hideTitle;
    @api isOuterComponent;
    @api tableInfoHasEditableColumns;

    // Optional, datatable specific
    @api showRowNumberColumn;
    @api hideCheckboxColumn; // (Not used if tableInfo is provided)
    @api resizeColumnDisabled;
    @api enableInfiniteLoading;

    @api hideDefaultColumnsActions;
    @api sortable;
    @api enableInlineEditing;

    // Optional, not available for manual input
    @api actions = actions;
    @api implementsDragAndDrop;
    @api customHandleNewEnabled;
    @api customHandleRowActionEnabled;
    @api customHandleSave;

    showSpinner;
    label = label;
   

    // Needed to give a different id to each individual instance of this component in the same page,
    // so that we can individually scope css dynamically for each of them
    instance = `instance${_numberOfCurrentInstance}`;

    _iconName;
    _childListName;
    _sobjectLabel;
    _sobjectLabelPlural;
    _accumulatedRecordsRetrieved = 0;
    _numberOfRecordsTitle;
    _isStyleApplied;
    _childObjectApiName;

    // If provided, other required attributes will be ignored
    _tableInfo;
    @api get tableInfo() {
        return this._tableInfo;
    }

    set tableInfo(value) {
        this._tableInfo = value;
        if (value) {
            this._accumulatedRecordsRetrieved = 0;
        }
    }


    @api get tableComponent() {
        return this.template.querySelector('c-copadocore-dynamic-datatable').tableComponent;
    }

    get iconName() {
        return this.headerIcon || this._iconName;
    }

    get title() {
        return this.customTitle || `${this._sobjectLabelPlural || ''} ${this._numberOfRecordsTitle ? '(' + this._numberOfRecordsTitle + ')' : ''}`;
    }

    get subtitle() {
        const items = this._numberOfRecordsTitle === '1' ? 'item' : 'items';
        return this.customSubtitle || `${this._numberOfRecordsTitle ? this._numberOfRecordsTitle + ' ' + items : ''}`;
    }

    _baseLightningLayoutClasses = 'slds-m-top_x-small';
    get lightningLayoutClasses() {
        return this.isOuterComponent ? this._baseLightningLayoutClasses : `${this._baseLightningLayoutClasses} slds-box slds-p-around_none`;
    }

    _baseHeaderClasses = 'slds-col slds-media slds-media_center slds-has-flexi-truncate';
    get headerClasses() {
        return this.isOuterComponent ? this._baseHeaderClasses : `${this._baseHeaderClasses} slds-p-top_medium slds-p-horizontal_medium`;
    }

    _baseSubheaderClasses = 'slds-col slds-grid slds-grid_align-spread slds-p-top_x-small';
    get subheaderClasses() {
        return this.isOuterComponent ? this._baseSubheaderClasses : `${this._baseSubheaderClasses} slds-p-horizontal_medium`;
    }

    _baseFooterClasses = 'slds-card__footer slds-m-top_none';
    get footerClasses() {
        return this.height !== 'auto' ? this._baseFooterClasses : `${this._baseFooterClasses} no-border-top`;
    }

    // If this.recordSize is received from the parent, we need to parse it from string to number: Number(this.recordSize)
    get numberOfRecords() {
        return Number(this.recordSize);
    }

    async connectedCallback() {
        _numberOfCurrentInstance++;
        // Retrieve related list configuration in connectedCallback instead of wired methods
        // since relationshipField is optional and, if it is never assigned, wired method is
        // is never called
        if (this.recordId) {
            this.showSpinner = true;
            await this._getRelatedListConfig();
            this.showSpinner = false;
        }
    }

    renderedCallback() {
        loadStyle(this, relatedListResources + '/relatedList.css');
        this._applyStyle();
    }

    // API EXPOSED

    @api handleRefresh() {
        this._accumulatedRecordsRetrieved = 0;
        this.template.querySelector('c-copadocore-dynamic-datatable').handleRefresh();
    }

    // PUBLIC

    handleRetrievedRows(event) {
        const numberOfRecordsRetrieved = event.detail.numberOfRecordsRetrieved;
        let numberOfRecordsTitle;

        if (numberOfRecordsRetrieved > this.numberOfRecords) {
            this._accumulatedRecordsRetrieved += this.numberOfRecords;
            numberOfRecordsTitle = `${this._accumulatedRecordsRetrieved}+`;
        } else {
            this._accumulatedRecordsRetrieved += numberOfRecordsRetrieved;
            numberOfRecordsTitle = `${this._accumulatedRecordsRetrieved}`;
        }

        this._numberOfRecordsTitle = numberOfRecordsTitle;

        this.dispatchEvent(new CustomEvent('retrievedrows', event));
    }

    handleCreateRecord() {
        if (this.customHandleNewEnabled) {
            this.dispatchEvent(new CustomEvent('createrecord'));
        } else {
            let defaultValues = '';
            if (this.recordId && this.relationshipField) {
                defaultValues = encodeDefaultFieldValues({
                    [this.relationshipField]: this.recordId
                });
            }

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this._childObjectApiName,
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: defaultValues,
                    useRecordTypeCheck: 1
                }
            });
        }
    }

    handleSearch(event) {
        const applySearchDebounced = getDebouncedFunction(this._applySearch, 500);
        applySearchDebounced(this, event.target.value);
    }

    handleRowAction(event) {
        if (this.customHandleRowActionEnabled) {
            this.dispatchEvent(new CustomEvent('rowaction', event));
        } else {
            const actionName = event.detail.action.name;
            const row = event.detail.row;
            this.handleDefaultActions(actionName, row);
        }
    }

    handleDefaultActions(actionName, row) {
        switch (actionName) {
            case 'view':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'view'
                    }
                });
                break;
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'edit'
                    }
                });
                break;
            case 'delete':
                this._handleDeleteRecord(row);
                break;
            default:
        }
    }

    handleGoToRelatedList() {
        if (this.recordId && this.childListName) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordRelationshipPage',
                attributes: {
                    recordId: this.recordId,
                    relationshipApiName: this.childListName,
                    actionName: 'view'
                }
            });
        }
    }

    handleDropRow(event) {
        this.dispatchEvent(new CustomEvent('droprow', event));
    }

    handleInlineEditSave(event) {
        this.dispatchEvent(new CustomEvent('inlineeditsave', event));
    }

    handleRecordsUpdated(event) {
        this._accumulatedRecordsRetrieved = 0;
        this.dispatchEvent(new CustomEvent('recordsupdated', event));
    }

    handleRowSelection(event) {
        this.dispatchEvent(new CustomEvent('rowselection', event));
    }

    handleHeaderAction(event) {
        this.dispatchEvent(new CustomEvent('headeraction', event));
    }

    handleSearchApplied(event) {
        if (!event.detail.withoutChanges) {
            const numberOfRecordsRetrieved = event.detail.numberOfRecordsRetrieved;
            if (event.detail.isRefresh && numberOfRecordsRetrieved > this.numberOfRecords) {
                this._accumulatedRecordsRetrieved = this.numberOfRecords;
                this._numberOfRecordsTitle = `${this._accumulatedRecordsRetrieved}+`;
            } else {
                this._accumulatedRecordsRetrieved = numberOfRecordsRetrieved;
                this._numberOfRecordsTitle = `${this._accumulatedRecordsRetrieved}`;
            }
        }
        this.dispatchEvent(new CustomEvent('searchapplied', event));
    }

    // PRIVATE

    async _getRelatedListConfig() {
        const safeFetchRelatedListConfig = handleAsyncError(this._fetchRelatedListConfig, {
            title: this.label.Related_List_Error
        });

        const relatedListConfig = await safeFetchRelatedListConfig(this, {
            parentId: this.recordId,
            fromObject: this.relatedList,
            relationshipField: this.relationshipField
        });

        if (relatedListConfig) {
            this._iconName = relatedListConfig.iconName;
            this.childListName = relatedListConfig.childListName;
            this._sobjectLabel = relatedListConfig.sobjectLabel;
            this._sobjectLabelPlural = relatedListConfig.sobjectLabelPlural;
            this._childObjectApiName = relatedListConfig.childObjectApiName;
        }
    }

    /*Separate first real column header from the left of the table*/
    _applyStyle() {
        if (!this._isStyleApplied) {
            let firstColumnIndex = 1;
            if (this.showRowNumberColumn || this.enableInlineEditing || this.tableInfoHasEditableColumns) {
                firstColumnIndex++;
            }
            if (!this.hideCheckboxColumn) {
                firstColumnIndex++;
            }
            const style = document.createElement('style');
            // TODO: add proper width to the same element where padding-left is applied,
            // in order to make resize border visible if column resizing is enabled
            style.innerText = `
                [data-instance="${this.instance}"] thead>tr>th:nth-child(${firstColumnIndex}) {
                    padding-left: var(--lwc-varSpacingXSmall);
                }
            `;
            this.template.querySelector('.related-list').appendChild(style);
            this._isStyleApplied = true;
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    _fetchRelatedListConfig(self, queryConfig) {
        return fetchRelatedListConfig(queryConfig);
    }

    _applySearch(searchTerm) {
        this._accumulatedRecordsRetrieved = 0;
        this.template.querySelector('c-copadocore-dynamic-datatable').handleSearch(searchTerm);
    }

    _handleDeleteRecord(row) {
        const deletePopup = this.template.querySelector('c-related-list-delete-popup');
        deletePopup.recordId = row.Id;
        deletePopup.sobjectLabel = this._sobjectLabel;
        deletePopup.show();
    }
}