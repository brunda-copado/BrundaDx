import { LightningElement, api } from 'lwc';

import getAttachment from '@salesforce/apex/ReadFromAttachmentCtrl.getAttachment';

import Search_this_list from '@salesforce/label/c.Search_this_list';
import ERROR from '@salesforce/label/c.ERROR';
import CCH_COMPLIANCE_FINDINGS from '@salesforce/label/c.CCH_COMPLIANCE_FINDINGS';
import ORG_ID from '@salesforce/label/c.ORG_ID';
import CCH_FILE_TYPE from '@salesforce/label/c.CCH_FILE_TYPE';
import CCH_FILE_NAME from '@salesforce/label/c.CCH_FILE_NAME';
import CCH_METADATA_TYPE from '@salesforce/label/c.CCH_METADATA_TYPE';
import Metadata_Name from '@salesforce/label/c.Metadata_Name';

import { handleAsyncError, flushPromises } from 'c/copadocoreUtils';

export default class ComplianceFindingGrid extends LightningElement {
    @api recordId;

    isLoading = false;
    searchValue = '';
    label = {
        Search_this_list,
        CCH_COMPLIANCE_FINDINGS
    };
    columns = this._getColumns();
    sortDirection = 'asc';
    visibleData = [];
    sortedBy;

    _disableLoadMore = false;
    _data = [];
    _filteredData = [];
    _offSetCount = 0;

    // PUBLIC

    async connectedCallback() {
        this.isLoading = true;

        const safeAttachment = handleAsyncError(this._getAttachment, { title: ERROR });
        const complianceFindings = await safeAttachment(this, { parentId: this.recordId, name: 'FindingMetadata.json' });

        if (complianceFindings) {
            this._data = JSON.parse(atob(complianceFindings));
            this._filteredData = this._data;

            this.visibleData = this._getRowsToDisplay(this._data);
        }

        this.isLoading = false;
    }

    onSearchFilter(event) {
        this.searchValue = event.target.value;
        this._offSetCount = 0;

        this._filteredData = this._searchTextInData(this._data, this.searchValue);
        this.visibleData = this._getRowsToDisplay(this._filteredData);
    }

    async onLoadMore(event) {
        const { target } = event;
        if (this.visibleData.length < this._filteredData.length && !this._disableLoadMore) {
            target.isLoading = true;
            await flushPromises();

            this.visibleData = this.visibleData.concat(this._getRowsToDisplay(this._filteredData));

            target.isLoading = false;
            await flushPromises();
        }
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this._filteredData];

        cloneData.sort(this._sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

        this._offSetCount = 0;
        this._filteredData = cloneData;

        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;

        this.visibleData = this._getRowsToDisplay(this._filteredData);
    }

    // PRIVATE

    _searchTextInData(dataRows, searchText) {
        var result = [];

        result = dataRows.filter((eachRow) => {
            return Object.values(eachRow).some(function (value) {
                return value.toLowerCase().includes(searchText.toLowerCase());
            });
        });

        return result;
    }

    _getRowsToDisplay(dataset) {
        let result;

        const rowsLimit = 20;

        if (dataset.length < rowsLimit) {
            this._disableLoadMore = true;
            result = dataset;
        } else {
            result = dataset.slice(this._offSetCount, this._offSetCount + rowsLimit);
            this._offSetCount = this._offSetCount + rowsLimit;
            this._disableLoadMore = false;
        }

        return result;
    }

    _sortBy(field, reverse) {
        const key = function (x) {
            return x[field];
        };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    _getAttachment(self, params) {
        return getAttachment(params);
    }

    _getColumns() {
        return [
            { label: ORG_ID, fieldName: 'orgId', hideDefaultActions: true, sortable: true },
            { label: CCH_FILE_TYPE, fieldName: 'fileType', hideDefaultActions: true, sortable: true },
            { label: CCH_FILE_NAME, fieldName: 'fileName', hideDefaultActions: true, sortable: true },
            { label: CCH_METADATA_TYPE, fieldName: 'metadataType', hideDefaultActions: true, sortable: true },
            { label: Metadata_Name, fieldName: 'metadataName', hideDefaultActions: true, sortable: true }
        ];
    }
}