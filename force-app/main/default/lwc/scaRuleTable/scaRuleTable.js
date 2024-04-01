import { LightningElement, api, track, wire } from 'lwc';
import getRules from '@salesforce/apex/GenerateScaRuleSetCtrl.getRulesFrom';
import RULE_NAME from '@salesforce/schema/Static_Code_Analysis_Rule__c.Rule_Name__c';
import PRIORITY from '@salesforce/schema/Static_Code_Analysis_Rule__c.Priority__c';
import MESSAGE from '@salesforce/schema/Static_Code_Analysis_Rule__c.Message__c';
import Name from '@salesforce/label/c.NAME';
import Prioriry from '@salesforce/label/c.PRIORITY';
import Message from '@salesforce/label/c.MESSAGE';
import { flushPromises } from 'c/copadocoreUtils';

export default class ScaRuleTable extends LightningElement {
    @api recordId;

    _error = '';
    _rowLimit = 10;
    _rowOffSet = 0;

    @track recordData = [];
    @track slicedData = [];
    sortDirection = 'asc';
    sortedBy = RULE_NAME.fieldApiName;
    isLoading = false;
    columns = this._getColumns();
    
    @wire(getRules, { recordId: '$recordId' })
    wiredTests(result) {
        this._wiredResults = result;
        if (result.data) {
            this.isLoading = true;
            const cloneData = [...result.data];
            cloneData.sort(this._sortBy(this.sortedBy, this.sortDirection === 'asc' ? 1 : -1));
            this.recordData = cloneData;
            this.slicedData = this.recordData.slice(this._rowOffSet).slice(0, this._rowLimit);
            this.isLoading = false;
        }
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.recordData];

        cloneData.sort(this._sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.slicedData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    async onLoadMore() {
        const currentRecord = this.slicedData;
        if (this.slicedData.length < this.recordData.length) {
            this.isLoading = true;
            await flushPromises();

            const offset = parseInt(this._rowLimit, 10) + parseInt(this._rowOffSet, 10);
            const currentData = this.recordData.slice(offset).slice(0, this._rowLimit);

            this.slicedData = currentRecord.concat(currentData);

            if (this.slicedData.length < this.recordData.length) {
                this._rowOffSet = offset;
            } else {
                this._rowOffSet = this.slicedData.length;
            }
        }

        this.isLoading = false;
        await flushPromises();
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
    _getColumns() {
        return [
            {
                label: Name,
                fieldName: RULE_NAME.fieldApiName,
                sortable: true,
                cellAttributes: { alignment: 'left' },
                initialWidth: 292,
                hideDefaultActions: true
            },
            {
                label: Prioriry,
                fieldName: PRIORITY.fieldApiName,
                type: 'number',
                sortable: true,
                cellAttributes: { alignment: 'left' },
                initialWidth: 114,
                hideDefaultActions: true
            },
            {
                label: Message,
                fieldName: MESSAGE.fieldApiName,
                wrapText: true,
                fixedWidth: 378,
                hideDefaultActions: true
            }
        ];
    }
}