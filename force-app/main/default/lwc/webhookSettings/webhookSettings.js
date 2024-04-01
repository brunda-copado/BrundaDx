import { LightningElement } from 'lwc';

import { columns, labels } from './constants';
import { reduceErrors } from 'c/copadocoreUtils';
import { getSortedData } from 'c/datatableService';
import { showToastError } from 'c/copadocoreToastNotification';

import getActionKeys from '@salesforce/apex/WebhookSettingsCtrl.getActionKeys';

export default class WebhookSettings extends LightningElement {
    actionKeys = [];
    filteredRows = [];

    labels = labels;
    showSpinner = true;
    showExpireAlert = false;

    sortedBy;
    sortDirection = 'asc';
    columns = columns;
    errors;


    async connectedCallback() {
        this.getData();
    }


    async getData() {
        try {
            this.showSpinner = true;
            this.showExpireAlert = false;
            this.actionKeys = await getActionKeys();
            this._formatRows();
            this.filteredRows = this.actionKeys;
        } catch (ex) {
            showToastError(this, { message: reduceErrors(ex) });
        } finally {
            this.showSpinner = false;
        }
    }


    handleNew() {
        this.template.querySelector('c-webhook-settings-form').new();
    }

    // TABLE

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
        this.filteredRows = this.actionKeys;
    }


    handleRowAction(event) {
        const action = event.detail.action.name;
        const actionKey = event.detail.row;

        switch (action) {
            case 'edit':
                this.template.querySelector('c-webhook-settings-form').edit(actionKey);
                break;
            case 'delete':
                this.template.querySelector('c-webhook-settings-delete').delete(actionKey);
                break;
            case 'copy':
                this.copyToClipboard(actionKey.key);
                break;
            default:
        }
    }


    copyToClipboard(textToCopy) {
        if (navigator.clipboard) {
            navigator.clipboard.writeText(textToCopy);
        } else {
            this.fallbackCopyToClipboard(textToCopy);
        }

        this.copied = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.copied = false;
        }, 1500);
    }


    fallbackCopyToClipboard(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;

        // Avoid scrolling to bottom
        textArea.style.top = '0';
        textArea.style.left = '0';
        textArea.style.position = 'fixed';

        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            document.execCommand('copy');
        } catch (err) {
            showToastError(this, { message: reduceErrors(err) });
        }

        document.body.removeChild(textArea);
    }


    _formatRows() {
        this.errors = { rows: {} };
        this.actionKeys.forEach((key) => {
            if (key.isUserApiKeyChanged) {
                key.formattedEndDate = `${labels.Expired}. ${labels.User_Api_Key_Changed}`;
                this.errors.rows[key.id] = {
                    title: labels.Key_Expired,
                    messages: [labels.Regenerate_Action_Api_Key]
                };
            }
            else if (key.isExpired) {
                key.formattedEndDate = `${key.endDate} - ${labels.Expired}`;
                this.errors.rows[key.id] = {
                    title: labels.Key_Expired,
                    messages: [labels.Extend_Action_Api_Key]
                };
            } else {
                key.formattedEndDate = key.endDate;
            }
        });

        if (Object.keys(this.errors.rows).length) {
            this.showExpireAlert = true;
        }
    }
}