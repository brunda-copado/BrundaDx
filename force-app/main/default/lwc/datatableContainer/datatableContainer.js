import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';

import Search from '@salesforce/label/c.Search';
import Filter from '@salesforce/label/c.Filter';
import DATATABLE_STATIC_RESOURCES from '@salesforce/resourceUrl/CustomDatatable';

import { getSearchedData } from 'c/datatableService';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

const SEARCH_EVENT = 'search';
const CLEAR_SEARCH_EVENT = 'clearsearch';
const FILTER_EVENT = 'filter';
const CLEAR_FILTER_EVENT = 'clearfilter';
const ENTER_KEY_CODE = 13;
const MINIMUM_SEARCH_TERM_LENGTH = 3;
export default class DatatableContainer extends LightningElement {
    @api iconName;
    @api iconSize = 'medium';
    @api hasBody = false;
    @api hasFooter = false;

    @api enableDefaultSearch = false;
    @api enableQuickFilter = false;
    @api rows = [];
    @api columns = [];

    data = [];
    searchValue = '';
    searchDataCount = 0;
    label = {
        Search,
        Filter
    };

    @api
    executeFilters() {
        const filter = this._setFilterRows();
        if (filter) {
            filter.executeFilters();
        }
    }

    @api
    executeSearch() {
        if (!this.searchValue) {
            this._clearSearch();
        } else {
            this._applySearch();
        }
    }

    @api
    clearFilters() {
        const filter = this._setFilterRows();
        if (filter) {
            filter.clearFilters();
        }
    }

    @api
    clearSearch() {
        if (this.searchValue) {
            this.template.querySelector("[data-field='searchInput']").value = '';
            this._clearSearchAttribute();
        }
    }

    connectedCallback() {
        this._loadCSSResources();
    }

    // TEMPLATE

    handleSearch(event) {
        if (event.keyCode === ENTER_KEY_CODE) {
            const searchTerm = event.target.value;
            const hasNoSearchTerm = !searchTerm || searchTerm === '' || searchTerm.trim() === '';
            if (hasNoSearchTerm) {
                this._clearSearch();
            } else {
                this.searchValue = searchTerm.trim();
                this._applySearch();
            }
        }
    }

    handleClearSearch(event) {
        const searchTerm = event.detail.value;
        const hasNoSearchTerm = !searchTerm || searchTerm === '' || searchTerm.trim() === '';
        if (hasNoSearchTerm) {
            this._clearSearch();
        }
    }

    handleApplyFilter(event) {
        if (event && event.detail) {
            const filterResult = event.detail;
            this.dispatchEvent(new CustomEvent(FILTER_EVENT, { detail: filterResult }));
        }
    }

    handleClearFilter(event) {
        this.dispatchEvent(new CustomEvent(CLEAR_FILTER_EVENT));
    }

    // PRIVATE

    _setFilterRows() {
        const filter = this.template.querySelector('c-datatable-filter');
        if (filter) {
            filter.rows = this.rows;
            return filter;
        }
    }

    async _loadCSSResources() {
        await loadStyle(this, DATATABLE_STATIC_RESOURCES + '/css/customDatatableContainer.css');
    }

    _clearSearch() {
        this._clearSearchAttribute();
        this.dispatchEvent(new CustomEvent(CLEAR_SEARCH_EVENT));
    }

    _clearSearchAttribute() {
        this.data = [];
        this.searchValue = '';
        this.searchDataCount = 0;
    }

    async _applySearch() {
        this.data = [];
        if (this.searchValue.length < MINIMUM_SEARCH_TERM_LENGTH) {
            return;
        } else {
            try {
                const filteredRawData = await getSearchedData(this.columns, this.rows, this.searchValue);
                if (filteredRawData) {
                    this.data = [...filteredRawData];
                }
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        }
        this.searchDataCount = this.data.length;
        this.dispatchEvent(new CustomEvent(SEARCH_EVENT, { detail: this._getSearchObj() }));
    }

    _getSearchObj() {
        return {
            searchedData: this.data,
            searchDataCount: this.searchDataCount,
            searchTerm: this.searchValue
        };
    }
}