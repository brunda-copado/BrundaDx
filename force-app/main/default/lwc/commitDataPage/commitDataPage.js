import { LightningElement, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { showToastError } from 'c/copadocoreToastNotification';
import { namespace, reduceErrors } from 'c/copadocoreUtils';
import { label, schema, sourceOptions, resource } from './constants';
import commitData from '@salesforce/apex/CommitDataCtrl.commitData';
import getDataTemplateFiltersConfiguration from '@salesforce/apex/CommitDataCtrl.getDataTemplateFiltersConfiguration';
import validateOrgCredential from '@salesforce/apex/CommitDataCtrl.validateOrgCredential';

export default class CommitDataPage extends NavigationMixin(LightningElement) {
    label = label;
    schema = schema;
    resource = resource;

    // from user story
    userStoryId;
    userStoryName;
    orgCredentialId;
    headerLabel;
    headerIcon;

    // inputs
    sourceOptions = sourceOptions;
    sourceType = 'ENVIRONMENT';
    dataTemplateId;
    dataSetId;
    commitMessage;

    isWorking = false;
    validEntryPoint = false;
    validOrgCredential = false;
    displayInvalidOrg = true;

    get showSpinner() {
        return (
            typeof this.userStoryId === 'undefined' ||
            typeof this.headerLabel === 'undefined' ||
            typeof this.headerIcon === 'undefined' ||
            typeof this.userStoryName === 'undefined' ||
            typeof this.orgCredentialId === 'undefined' ||
            this.isWorking
        );
    }

    get showDataTemplateConfiguration() {
        return this.sourceType === 'ENVIRONMENT';
    }

    get showDataSetConfiguration() {
        return this.sourceType === 'DATASET';
    }

    get showFilterConfiguration() {
        return this.showDataTemplateConfiguration;
    }

    get disableInputs() {
        return !this.orgCredentialId || !this.validOrgCredential;
    }

    connectedCallback() {
        loadStyle(this, resource.HIDE_LIGHTNING_HEADER);
    }

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        this.validEntryPoint = false;
        if (pageReference && pageReference.state) {
            const parameterName = (!!namespace ? namespace : 'c__') + 'User_Story';
            this.userStoryId = pageReference.state[parameterName];
            if (this.userStoryId) {
                this.validEntryPoint = true;
            }
            this._resetInputs();
            this._resetFilters();
        }
    }

    @wire(getObjectInfo, { objectApiName: '$schema.USER_STORY_DATA_COMMIT' })
    getObjectInfo({ error, data }) {
        if (data) {
            this.headerLabel = data.label;
            this.headerIcon = data.themeInfo.iconUrl;
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    @wire(getRecord, { recordId: '$userStoryId', fields: [schema.USER_STORY_NAME, schema.USER_STORY_ORG_CREDENTIAL] })
    getUserStory({ error, data }) {
        if (data) {
            this.userStoryName = getFieldValue(data, schema.USER_STORY_NAME);
            this.orgCredentialId = getFieldValue(data, schema.USER_STORY_ORG_CREDENTIAL);
            if (!this.orgCredentialId) {
                showToastError(this, { message: label.NO_ORG_CREDENTIAL_ON_USER_STORY, mode: 'sticky' });
            } else {
                this._validateOrgCredential();
            }
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    @wire(getRecord, { recordId: '$dataTemplateId', fields: [schema.DATA_TEMPLATE_MAIN_OBJECT] })
    async getDataTemplate({ error, data }) {
        if (data) {
            this.isWorking = true;
            const objectName = getFieldValue(data, schema.DATA_TEMPLATE_MAIN_OBJECT);

            const dataTemplateFiltersConfiguration = await getDataTemplateFiltersConfiguration({ dataTemplateId: this.dataTemplateId });

            const dataFilters = this.template.querySelector('c-data-filters');
            if (dataFilters) {
                dataFilters.defaultFilters = dataTemplateFiltersConfiguration.filters;
                dataFilters.defaultFilterLogic = dataTemplateFiltersConfiguration.filterLogic;
                // this setter will reload the fields available for the filter and optionally will configure the default filters
                dataFilters.objectName = objectName;
            }
            this.isWorking = false;
        }
        if (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    handleChangeSource(event) {
        this.sourceType = event.detail.value;
    }

    handleChangeDataTemplate(event) {
        this.dataTemplateId = event.detail.value[0];
        if (!this.dataTemplateId) {
            this._resetFilters();
        }
    }

    handleChangeDataSet(event) {
        this.dataSetId = event.detail.value[0];
    }

    handleChangeCommitMessage(event) {
        this.commitMessage = event.detail.value;
    }

    async handleClickCommit() {
        this.isWorking = true;

        const allValid = this._validateInputs();
        if (allValid) {
            try {
                const dataFilters = this.template.querySelector('c-data-filters');
                let filters;
                let filterLogic;
                if (dataFilters) {
                    filters = dataFilters.filters;
                    filterLogic = dataFilters.filterLogic;
                }

                await commitData({
                    userStoryId: this.userStoryId,
                    sourceType: this.sourceType,
                    dataTemplateId: this.dataTemplateId,
                    dataSetId: this.dataSetId,
                    commitMessage: this.commitMessage,
                    filters: filters,
                    filterLogic: filterLogic
                });

                this._navigateToUserStory();
            } catch (error) {
                const errorMessage = reduceErrors(error);
                showToastError(this, { message: errorMessage });
            }
        } else {
            showToastError(this, { message: label.COMPLETE_ALL_FIELDS });
        }

        this.isWorking = false;
    }

    handleClickCancel() {
        this.displayInvalidOrg = false;
        this._navigateToUserStory();
    }

    _navigateToUserStory() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.userStoryId,
                objectApiName: schema.USER_STORY,
                actionName: 'view'
            }
        });
    }

    _validateInputs() {
        const allValid = [...this.template.querySelectorAll('lightning-input-field')].reduce((validSoFar, inputField) => {
            return validSoFar && inputField.reportValidity();
        }, true);
        return allValid;
    }

    _resetInputs() {
        this.dataTemplateId = undefined;
        this.dataSetId = undefined;
        this.commitMessage = undefined;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            if (element.value) {
                element.reset();
            }
        });
    }

    _resetFilters() {
        const dataFilters = this.template.querySelector('c-data-filters');
        if (dataFilters) {
            dataFilters.objectName = null;
            dataFilters.defaultFilters = [];
            dataFilters.defaultFilterLogic = null;
            dataFilters.filters = [];
            dataFilters.filterLogic = null;
        }
    }

    async _validateOrgCredential() {
        try {
            this.validOrgCredential = await validateOrgCredential({ orgCredId: this.orgCredentialId });
            if (!this.validOrgCredential && this.displayInvalidOrg) {
                this._showToastForInvalidCredential();
            }
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    _showToastForInvalidCredential() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.orgCredentialId,
                actionName: 'view'
            }
        }).then(u => {
            const messageLabel = this.label.CREDENTAIL;
            const errorMessageData = [{ url: u, label: messageLabel }];
            const errorMessage = this.label.COMMIT_DATA_INVALID_ORG_MESSAGE;
            showToastError(this, { message: errorMessage, messageData: errorMessageData });
        });
    }
}