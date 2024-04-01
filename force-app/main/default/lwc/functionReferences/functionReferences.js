import { LightningElement, api } from 'lwc';

import { reduceErrors } from 'c/copadocoreUtils';
import { getSortedData } from 'c/datatableService';
import { showToastError } from 'c/copadocoreToastNotification';

import AUTOMATIONS from '@salesforce/label/c.Automations';
import LOADING from '@salesforce/label/c.LOADING';
import ITEMS from '@salesforce/label/c.Items';
import NAME from '@salesforce/label/c.NAME';
import TYPE from '@salesforce/label/c.TYPE';
import PARENTRECORD from '@salesforce/label/c.ParentRecord';

import fetchReferences from '@salesforce/apex/FunctionReferences.getReferences';

export default class FunctionReferences extends LightningElement {
    @api recordId;

    rows = [];
    filteredRows = [];
    showSpinner = true;
    sortedBy;
    sortDirection = 'asc';
    labels = {
        AUTOMATIONS,
        LOADING,
        ITEMS,
        NAME,
        TYPE,
        PARENTRECORD
    }

    columns = [
        {
            label: this.labels.NAME,
            fieldName: 'recordLink',
            type: 'url',
            searchable: true,
            sortable: true,
            typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
        },
        { label: this.labels.TYPE, fieldName: 'type', searchable: true, sortable: true },
        {
            label: this.labels.PARENTRECORD,
            fieldName: 'parentLink',
            type: 'url',
            searchable: true,
            sortable: true,
            typeAttributes: { label: { fieldName: 'parentName' }, target: '_blank' }
        }
    ];

    async connectedCallback() {
        try {
            this.rows = await fetchReferences({ recordId: this.recordId });
            this.rows = this.rows.map((row) => (
                {
                    ...row,
                    recordLink: '/' + row.id,
                    parentLink: '/' + row.parentId
                }
            ));
            this.filteredRows = this.rows;
        } catch (error) {
            showToastError(this, { message: reduceErrors(error) });
        } finally {
            this.showSpinner = false;
        }
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;

        this.filteredRows = [
            ...getSortedData(this.columns, this.filteredRows, {
                name: fieldName,
                sortDirection
            })
        ];
        this.sortDirection = sortDirection;
        this.sortedBy = fieldName;
    }

    handleSearch(event) {
        this.filteredRows = [...event.detail.searchedData];
    }

    handleClearSearch() {
        this.filteredRows = this.rows;
    }
}