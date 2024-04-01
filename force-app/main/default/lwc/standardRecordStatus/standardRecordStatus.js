import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import getStandardRecordsBundle from '@salesforce/apex/StandardRecordStatusCtrl.getStandardRecordsBundle';
import getInsertedBundle from '@salesforce/apex/StandardRecordStatusCtrl.getInsertedBundle';
import updateRecords from '@salesforce/apex/StandardRecordStatusCtrl.updateRecords';
import getResources from '@salesforce/apex/StandardRecordStatusCtrl.getResources';

import Name from '@salesforce/label/c.NAME';
import STATUS from '@salesforce/label/c.STATUS';
import MESSAGE from '@salesforce/label/c.MESSAGE';
import OldValue from '@salesforce/label/c.OldValue';
import NewValue from '@salesforce/label/c.NewValue';
import ObjectType from '@salesforce/label/c.ObjectType';
import Loading from '@salesforce/label/c.LOADING';
import Error from '@salesforce/label/c.ERROR';

import Created from '@salesforce/label/c.Created';
import NotUpdated from '@salesforce/label/c.NotUpdated';
import NotCreated from '@salesforce/label/c.NotCreated';

import NoExtension from '@salesforce/label/c.NoExtension';
import SelectExtension from '@salesforce/label/c.SelectExtension';
import ViewDifferences from '@salesforce/label/c.ViewDifferences';
import GenerateExtension from '@salesforce/label/c.GenerateExtension';
import SetupExtensionInstruction from '@salesforce/label/c.SetupExtensionInstruction';

export default class StandardRecordBundleStatus extends LightningElement {
    @api
    recordId;

    standardResources = [];
    selectedResourceId;

    activeRecordId;
    activeNewRecord = {};
    activeOldRecord = {};

    isLoading = true;
    data = [];

    isAnyRecordDifferent = false;

    label = {
        NoExtension,
        SelectExtension,
        GenerateExtension,
        SetupExtensionInstruction,
        Loading
    }

    columns = [
        {
            label: ObjectType, fieldName: 'objectName', wrapText: true
        },
        {
            label: Name, fieldName: 'recordLink', type: 'url', wrapText: false,
            typeAttributes: { label: { fieldName: 'recordName' }, target: '_blank' }
        },
        {
            label: STATUS, wrapText: true,
            cellAttributes: { iconName: { fieldName: 'statusIcon' }, class: { fieldName: 'statusClass' } }
        },
        {
            label: MESSAGE, fieldName: 'message', wrapText: true
        },
        {
            type: 'action',
            typeAttributes: { rowActions: [{ label: ViewDifferences, name: 'showDetail' }] },
        }
    ];


    diffColumns = [
        {
            label: Name, fieldName: 'name',
            cellAttributes: { iconName: { fieldName: 'statusIcon' } }
        },
        {
            label: OldValue, fieldName: 'oldValue', wrapText: true
        },
        {
            label: NewValue, fieldName: 'newValue', wrapText: true,
        }
    ];

    get hasStandardResources() {
        return !!(this.standardResources.length);
    }

    get resourceOptions() {
        return this.standardResources.map(resource => ({
            value: resource.Id,
            label: resource.Name
        }));
    }

    get hasStandardRecords() {
        return !!(this.data.length);
    }

    get hasNoRecords() {
        return (!this.isLoading && this.selectedResourceId && !this.hasStandardRecords);
    }

    get bundleDiff() {
        const result = [];

        const newRecord = this.activeNewRecord || {};
        const oldRecord = this.activeOldRecord || {};

        for (let name in newRecord) {
            const isSame = oldRecord[name] === newRecord[name];

            result.push({
                name,
                oldValue: oldRecord[name],
                newValue: newRecord[name],
                statusIcon: (isSame) ? 'action:approval' : 'action:close'
            });
        }

        return result;
    }

    get selectedResource() {
        return this.standardResources.find(standardResource => standardResource.Id === this.selectedResourceId);
    }

    async connectedCallback() {
        try {
            this.standardResources = await getResources();
        }
        catch (error) {
            this.showError(error);
        }
        finally {
            this.isLoading = false;
        }
    }

    handleResourceChange(event) {
        this.selectedResourceId = event.detail.value;
        this.showBundleDiff();
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;

        if (actionName === 'showDetail') {
            const modal = this.template.querySelector('c-copadocore-modal');
            const { oldRecord, newRecord, recordId } = event.detail.row;

            this.activeRecordId = recordId;
            this.activeOldRecord = oldRecord;
            this.activeNewRecord = newRecord;

            modal.show();
        }
    }

    async showBundleDiff() {
        this.isLoading = true;

        try {
            await this.setRecordStatuses();
        }
        catch (error) {
            this.showError(error);
        }
        finally {
            this.isLoading = false;
        }
    }

    async updateRecord() {

        this.isLoading = true;
        const resourceName = this.resourceName();

        try {
            await updateRecords({ resourceName });
            this.template.querySelector('c-copadocore-modal').hide();
            await this.setRecordStatuses();
        }
        catch (error) {
            this.showError(error);
        }
        finally {
            this.isLoading = false;
        }
    }

    async setRecordStatuses() {
        const serializedBundle = await getStandardRecordsBundle({ resourceId: this.selectedResourceId });
        const standardBundle = JSON.parse(serializedBundle);
        const result = [];
        let isAnyRecordDifferent = false;

        for (let i = 0; i < standardBundle.RecordSetBundles?.length; i++) {
            const bundle = standardBundle.RecordSetBundles[i];
            const serializedBundle = JSON.stringify(bundle);
            const insertedRecord = await getInsertedBundle({ serializedBundle });
            const oldRecordsByName = this.groupByName(insertedRecord.records, insertedRecord.externalIdField) || {};

            for (let j = 0; j < bundle.Records.length; j++) {
                let newRecord = bundle.Records[j];
                const recordName = newRecord[insertedRecord.externalIdField];
                const oldRecord = oldRecordsByName[recordName] || {};

                const recordId = oldRecord.Id;
                const isNew = !recordId;
                const isSame = this.isSame(oldRecord, newRecord);
                isAnyRecordDifferent = (isAnyRecordDifferent || !isSame);

                result.push({
                    recordId,
                    oldRecord,
                    newRecord,
                    recordName: recordName,
                    recordLink: '/' + recordId,
                    objectName: bundle.ObjectType,
                    variant: (isSame) ? 'success' : 'warning',
                    statusIcon: (isSame) ? 'action:approval' : 'action:close',
                    message: (isNew) ? NotCreated : ((isSame) ? Created : NotUpdated)
                });
            }
        }

        this.data = result;
        this.isAnyRecordDifferent = isAnyRecordDifferent;
    }

    resourceName() {
        let result = this.resourceOptions.filter(option => option.value === this.selectedResourceId);

        return (result.length) ? result[0].label : null;
    }

    groupByName(records, externalId) {
        return records?.reduce((result, record) => {
            result[record[externalId]] = record;
            return result;
        }, {});
    }

    isSame(oldRecord, newRecord) {
        let result = true;

        for (let key of Object.keys(newRecord)) {
            if (this.isBlackListed(key) || this.isId(newRecord[key])) {
                delete newRecord[key];
                delete oldRecord[key];
            }

            if (oldRecord[key] != newRecord[key]) {
                result = false;
            }
        }

        return result;
    }

    isBlackListed(fieldName) {
        const blackListedFields = {
            'Id': true,
            'attributes': true,
            'CreatedDate': true,
            'LastViewedDate': true,
            'SystemModstamp': true,
            'attributes.url': true,
            'LastModifiedDate': true,
            'LastReferencedDate': true,
            'Worker_Size__c': true,
            'copado__Worker_Size__c': true,
        };

        return blackListedFields[fieldName];
    }

    isId(value) {
        return (value && (value.length === 15 || value.length === 18));
    }

    showError(error) {
        const title = error?.body?.exceptionType || Error;
        const message = error?.body?.message || error?.message || error;

        this.showToast(title, message);
    }

    showToast(title, message, variant = 'error') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}