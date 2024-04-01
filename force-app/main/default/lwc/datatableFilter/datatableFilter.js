import { LightningElement, api } from 'lwc';

import { constants, label } from './constants';
import { getFiltersByColumns, getFilteredData } from 'c/datatableService';

export default class DatatableFilter extends LightningElement {
    @api rows = [];
    @api columns = [];
    @api defaultOperation = constants.INCLUDES;

    label = label;
    filtersByColumn;

    _isOpen = false;
    _scrollEventCallback;
    _filterByField = new Map();

    @api
    clearFilters() {
        this.filtersByColumn = [];
        this._filterByField = new Map();
        this._fetchFilterByColumn();
    }

    @api
    executeFilters() {
        this.saveFilter();
    }

    connectedCallback() {
        this._fetchFilterByColumn();

        if (!this.defaultOperation || this.defaultOperation !== constants.EQUALS) {
            this.defaultOperation = constants.INCLUDES;
        } else {
            this.defaultOperation = constants.EQUALS;
        }
    }

    // PUBLIC

    showFilters() {
        const el = this.template.querySelector('.collapsible-filter');
        const filterContainerElem = this.template.querySelector('.filter-container');

        this._isOpen = !this._isOpen;

        if (this._isOpen) {
            el.classList.remove('collapsed');
            el.classList.add('expanded');

            // calculates container height
            setTimeout(() => {
                filterContainerElem.style.height = `${el.clientHeight - 101}px`;
            }, 0);
        } else {
            el.classList.remove('expanded');
            el.classList.add('collapsed');

            // remove listener
            filterContainerElem.removeEventListener('scroll', this._scrollEventCallback);
        }
    }

    removeAllFilters() {
        this.clearFilters();
        this._clearFilterEvent();
    }

    saveFilter() {
        this._filterByField = new Map();
        this.template.querySelectorAll('c-filter-columns').forEach((el) => {
            el.validate();
        });
    }

    handleValidateFilterColumn(event) {
        const filterObject = event.detail;
        this._filterByField.set(filterObject.fieldName, filterObject);
        if (this._filterByField.size === this.filtersByColumn.length) {
            this._filterByField = this._removeEmptyFilter(this._filterByField);
            if (this._filterByField && this._filterByField.size > 0) {
                this._applyFilter();
            } else {
                this.removeAllFilters();
            }
        }
    }

    // PRIVATE

    async _fetchFilterByColumn() {
        if (this.columns) {
            const filterConfig = await getFiltersByColumns(this.columns, this.rows);
            if (filterConfig && filterConfig.length) {
                this.filtersByColumn = filterConfig;
            }
        }
    }

    _removeEmptyFilter(filterByField) {
        const result = new Map();
        filterByField.forEach((eachFilter) => {
            const fieldName = eachFilter.fieldName;
            if (this._hasFilterValue(eachFilter)) {
                result.set(fieldName, eachFilter);
            }
        });
        return result;
    }

    _hasFilterValue(eachFilter) {
        const fieldValue = eachFilter.searchTerm ? (eachFilter.searchTerm + '').trim().toLowerCase() : '';
        const minFieldValue = eachFilter.filterRangeMin ? (eachFilter.filterRangeMin + '').trim().toLowerCase() : '';
        const maxFieldValue = eachFilter.filterRangeMax ? (eachFilter.filterRangeMax + '').trim().toLowerCase() : '';
        if (fieldValue || minFieldValue || maxFieldValue) {
            return true;
        }
        return false;
    }

    async _applyFilter() {
        const data = await getFilteredData(this._filterByField, this.rows);
        this._applyFilterEvent(data);
    }

    _clearFilterEvent() {
        this.dispatchEvent(new CustomEvent(constants.CLEAR_FILTER_EVENT));
    }

    _applyFilterEvent(data) {
        data = data ? data : [];
        const filterResult = {
            searchedData: data,
            searchDataCount: data.length,
            searchTerm: undefined,
            filterFields: [...this._filterByField.keys()]
        };
        this.dispatchEvent(new CustomEvent(constants.FILTER_EVENT, { detail: filterResult }));
    }
}