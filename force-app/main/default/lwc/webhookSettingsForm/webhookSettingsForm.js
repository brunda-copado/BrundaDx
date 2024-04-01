import { LightningElement, api, wire } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { labels, schema } from './constants';
import { showToastError } from 'c/copadocoreToastNotification';
import { handleAsyncError, reduceErrors } from 'c/copadocoreUtils';

import search from '@salesforce/apex/CustomLookupComponentHelper.search';
import saveActionKey from '@salesforce/apex/WebhookSettingsCtrl.saveActionKey';

export default class WebhookSettingsForm extends LightningElement {
    actions;
    expiresInDays = 1;
    labels = labels;


    user;
    actionKey;
    modalTitle;
    selectedUserId;
    actionOptions = [];

    async connectedCallback() {
        this.selectedUserId = currentUserId;
    }

    @api
    new() {
        this.modalTitle = labels.AddNewActionKey;
        this.actionKey = {};
        this.expiresInDays = 30;
        this.actions = [];
        this.selectedUserId = currentUserId;
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api
    edit(actionKey) {
        this.modalTitle = labels.EditActionKey;
        this.actionKey = actionKey;
        this.expiresInDays = actionKey.expiresInDays;
        this.actions = actionKey.actions.split(',');
        this.selectedUserId = actionKey.userId;
        this.template.querySelector('c-copadocore-modal').show();
    }


    @wire(getRecord, {
        recordId: '$selectedUserId',
        fields: [schema.NAME_FIELD, schema.EMAIL_FIELD]
    })
    wiredUser(value) {
        const { data, error } = value;
        if (data) {
            this.user = {
                Id: this.selectedUserId,
                Name: getFieldValue(data, schema.NAME_FIELD),
                Email: getFieldValue(data, schema.EMAIL_FIELD)
            };
        } else if (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    @wire(getPicklistValues, { fieldApiName: schema.PIPELINE_ACTIONS_FIELD, recordTypeId: '012000000000000AAA' })
    wiredActions({ data, error }) {
        if (data) {
            this.actionOptions = [...data.values];
            this.actionOptions.push({ label: labels.RunJobTemplate, value: 'RunJobTemplate' });
            this.actionOptions.push({ label: labels.RunTests, value: 'RunTests' });
        } else if (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }


    closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }


    async save() {

        const expiresInDays = this.template.querySelector('lightning-input[data-id="expiresInDays"]');
        const actions = this.template.querySelector('lightning-dual-listbox');

        if (!actions.validity.valid || !expiresInDays.validity.valid) {
            actions.reportValidity();
            expiresInDays.reportValidity();
            return;
        }

        try {
            this.actionKey.actions = [...actions.value].sort().join(',');
            this.actionKey.userId = this.selectedUserId;
            // eslint-disable-next-line radix
            this.actionKey.expiresInDays = parseInt(expiresInDays.value);

            await saveActionKey({ actionKeyData: JSON.stringify(this.actionKey) });

            this.dispatchEvent(new CustomEvent('save'));
            this.template.querySelector('c-copadocore-modal').hide();
        } catch (ex) {
            showToastError(this, { message: reduceErrors(ex) });
        }
    }


    initLookup() {
        const lookup = this.template.querySelector('c-lookup');
        if (lookup) {
            lookup.selection = [
                {
                    Id: this.user.Id,
                    sObjectType: 'User',
                    icon: 'standard:user',
                    title: this.user.Name,
                    subtitle: `${labels.Username}: ${this.user.Email}`
                }
            ];
        }
    }


    async handleLookupSearch(event) {
        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._search, {
            title: labels.Error_Searching_Records
        });

        const queryConfig = {
            searchField: 'Name',
            objectName: 'User',
            searchKey: event.detail.searchTerm,
            extraFilterType: undefined,
            filterFormattingParameters: undefined
        };

        const result = await safeSearch(this, { queryConfig, objectLabel: 'User', iconName: 'standard:user' });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }


    getSelectedId(lookupData) {
        if (lookupData.detail.length) {
            this.selectedUserId = lookupData.detail[0];
        } else {
            this.selectedUserId = undefined;
        }
    }


    get isDisabled() {
        return true; //User lookup ready to be used for Admin
    }


    _search(self, queryConfig) {
        return search(queryConfig);
    }
}