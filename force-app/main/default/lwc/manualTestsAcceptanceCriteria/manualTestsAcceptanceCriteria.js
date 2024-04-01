import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import fetchAcceptanceCriteria from '@salesforce/apex/ManualTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria';
import storeAcceptanceCriteria from '@salesforce/apex/ManualTestsAcceptanceCriteriaCtrl.storeAcceptanceCriteria';
import getRecentlyViewedUsers from '@salesforce/apex/ManualTestsAcceptanceCriteriaCtrl.getRecentlyViewedUsers';
import getRecentlyModifiedGroups from '@salesforce/apex/ManualTestsAcceptanceCriteriaCtrl.getRecentlyModifiedGroups';
import lookupSearch from '@salesforce/apex/CustomLookupComponentHelper.search';

import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { uniqueKey, autoFormValidation, reduceErrors, handleAsyncError, flushPromises } from 'c/copadocoreUtils';

import { schema, labels, typeOptions, testerScopeOptions } from './constants';

const INPUT_NUMBER_LENGTH = 10;
const NOTE_LENGTH = 200;

export default class manualTestsAcceptanceCriteria extends LightningElement {
    recordId;
    objectApiName;

    labels = labels;
    schema = schema;
    typeOptions = typeOptions;
    testerScopeOptions = testerScopeOptions;

    inputLength = INPUT_NUMBER_LENGTH;
    noteLength = NOTE_LENGTH;

    isLoading = false;
    editableMode = false;

    recentlyViewedUsers;
    recentlyModifiedGroups;

    _metricsBackup;
    _metrics;

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        if (pageReference && pageReference.state) {
            this.recordId = pageReference.attributes.recordId;
            this.objectApiName = pageReference.attributes.objectApiName;
        }
    }

    @wire(getRecentlyViewedUsers)
    getRecentlyViewedUsers(result) {
        if (result) {
            this.recentlyViewedUsers = result.data;
        }
    }

    @wire(getRecentlyModifiedGroups)
    getRecentlyModifiedGroups(result) {
        if (result) {
            this.recentlyModifiedGroups = result.data;
        }
    }

    connectedCallback() {
        this._getData();
    }

    // GETTER

    get metricList() {
        return this._metrics;
    }

    get isMetricListEmpty() {
        return this._metrics.length === 0;
    }

    // PUBLIC

    async handleLookupSearch(event) {
        const metricId = event.target.dataset.metricid;
        const index = this._metrics.findIndex(item => item.id === metricId);
        const testerScope = this._metrics[index].testerScope;

        const iconName = (!testerScope || testerScope === 'User')  ? 'standard:user' : 'standard:groups';
        const objectName = (!testerScope || testerScope === 'User') ? 'User' : 'Group';
        const extraFilterType = (!testerScope || testerScope === 'User') ? undefined : `RegularGroupsFilter`;

        const lookupElement = event.target;

        const safeSearch = handleAsyncError(this._lookupSearch, {
            title: this.labels.ERROR_SEARCHING_RECORDS
        });

        const queryConfig = {
            searchField: 'Name',
            objectName,
            searchKey: event.detail.searchTerm,
            extraFilterType,
            filterFormattingParameters: undefined
        };

        
        const result = await safeSearch(this, { queryConfig, objectLabel: objectName, iconName });

        if (result) {
            lookupElement.setSearchResults(result);
        }
    }


    testerScopeFieldChangeHandler(event) {
        const metricId = event.target.dataset.metricid;
        const index = this._metrics.findIndex(item => item.id === metricId);
        this._metrics[index].testerScope = event.target.value;

        this._initRecentlyViewedInLookup(this._metrics[index].testerScope, metricId);

        this._metrics[index].editableTesters = this._metrics[index].testerScope === 'Group';
        if (!this._metrics[index].editableTesters) {
            this._metrics[index].minimumTesters = 1;
        }
        this._resetLookup(index, metricId);

        // @Note: needed in order to switch from editable to disabled lightning-input for minimum approvers
        const backup = this._metrics;
        this._metrics = [];
        this._metrics = backup;
    }
    
    testerFieldChangeHandler(event) {
        const metricId = event.target.dataset.metricid;
        const index = this._metrics.findIndex(item => item.id === metricId);

        this._metrics[index].tester = event.target.getSelection().length ? event.target.getSelection()[0] : '';
    }

    typeFieldChangeHandler(event) {
        const metricId = event.target.dataset.metricid;
        const index = this._metrics.findIndex(item => item.id === metricId);
        this._metrics[index].type = event.target.value;
    }

    minimumTestersFieldChangeHandler(event) {
        const metricId = event.target.dataset.metricid;
        const index = this._metrics.findIndex(item => item.id === metricId);
        this._metrics[index].minimumTesters = event.target.value;
    }

    async editMetrics() {
        if (this._metrics.length === 0) {
            this.addMetric();
        }

        this.editableMode = true;

        // @Note: We need to flush promises for lookup to be available in next querySelector
        await flushPromises();

        this._metrics.forEach((metric) => {
            const testersLookup = this.template.querySelector(`c-lookup[data-metricid="${metric.id}"]`);

            if (testersLookup) {
                const recents = metric.testerScope === 'User' ? this.recentlyViewedUsers : this.recentlyModifiedGroups;
                testersLookup.setDefaultResults(recents);
                if (metric.tester) {
                    testersLookup.selection = [
                        {
                            Id: metric.tester.id,
                            sObjectType: metric.tester.sObjectType,
                            icon: metric.tester.icon,
                            title: metric.tester.title,
                            subtitle: metric.tester.subtitle
                        }
                    ];
                }
            }
        });
    }

    async addMetric() {
        let newMetric = {
            id: uniqueKey('criteria'),
            metric: '',
            testerScope: 'User',
            editableTesters: false,
            minimumTesters: 1
        };
        this._metrics = [...this._metrics, newMetric];

        // @Note: We need to flush promises for lookup to be available in next querySelector
        await flushPromises();

        this._initRecentlyViewedInLookup('User', newMetric.id);
    }

    deleteMetric(event) {
        const metricId = event.target.dataset.metricid;
        this._metrics = this._metrics.filter(o => o.id !== metricId);
        if (this._metrics.length === 0) {
            this.addMetric();
        }
    }

    handleEditCancel() {
        this._metrics = JSON.parse(JSON.stringify(this._metricsBackup));
        this.editableMode = false;
    }

    validateData() {
        if (this._lookupsEmpty()) {
            showToastError(this, { message: 'Please complete all required fields.' });
        } else if (this._areMetricsDuplicated()) {
            showToastError(this, { message: labels.ERROR_ACCEPTANCE_CRITERIA_DUPLICATED_METRICS });
        } else if (autoFormValidation(this.template, this)) {
            this._shapeCriteriaJson();
            this._save();
        }
    }

    // PRIVATE

    _initRecentlyViewedInLookup(testerScope, metricId) {
        const recents = testerScope === 'User' ? this.recentlyViewedUsers : this.recentlyModifiedGroups;

        const testersLookup = this.template.querySelector(`c-lookup[data-metricid="${metricId}"]`);
        if (testersLookup) {
            testersLookup.setDefaultResults(recents);
        }
    }

    _areMetricsDuplicated() {
        let result = false;

        let uniqueSet = {};
        this._metrics.forEach(item => {
            let uniqueString = item.testerScope + item.tester.title;
            if (uniqueSet[uniqueString]) {
                result = true;
            } else {
                uniqueSet[uniqueString] = uniqueString;
            }
        });
        
        return result;
    }

    _lookupsEmpty() {
        let result = false;

        this._metrics.forEach(item => {
            if (!item.tester) {
                result = true;
            }
        });
        
        return result;
    }

    async _save() {
        this.isLoading = true;
        try {
            await storeAcceptanceCriteria({ body: JSON.stringify(this._shapeCriteriaJson(), null, 4), recordId: this.recordId });
            this.editableMode = false;
            this._metricsBackup = JSON.parse(JSON.stringify(this._metrics));
            this.isLoading = false;
            showToastSuccess(this, { message: labels.CONFIRM_ACCEPTANCE_CRITERIA_SAVE });
        } catch (error) {
            this._metricsBackup = [];
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    _shapeCriteriaJson() {
        let result = [];

        this._metrics.forEach(item => {
            result.push({
                testerScope: item.testerScope,
                tester: item.tester,
                type: item.type,
                minimumTesters: item.minimumTesters,
                editableTesters: item.testerScope === 'Group'
            });
        });

        return result;
    }

    _extractMetrics(metricsJson) {
        let result = [];

        if (metricsJson && metricsJson.length) {
            result = metricsJson.map((metric) => {
                metric.id = uniqueKey('criteria')
                return metric;
            });
        }

        return result;
    }

    async _getData() {
        this.isLoading = true;
        try {
            const response = await fetchAcceptanceCriteria({ recordId: this.recordId });
            this._metricsBackup = this._extractMetrics(JSON.parse(response));
            this._metrics = JSON.parse(JSON.stringify(this._metricsBackup));
        } catch (error) {
            this._metricsBackup = [];
            showToastError(this, { message: reduceErrors(error) });
        }
        this.isLoading = false;
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
    */
    _lookupSearch(self, queryConfig) {
        return lookupSearch(queryConfig);
    }

    _resetLookup(index, metricId) {
        this._metrics[index].tester = '';
        const testersLookup = this.template.querySelector(`c-lookup[data-metricid="${metricId}"]`);
        testersLookup.selection = [];
    }
}