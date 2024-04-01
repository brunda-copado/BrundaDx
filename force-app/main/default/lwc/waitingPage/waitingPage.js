import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

import getFieldsFromFieldSet from '@salesforce/apex/LockBundleCtrl.getFieldsFromFieldSet';
import startActionFlow from '@salesforce/apex/PerformUserStoryAction.startActionFlow';
import fetchCommits from '@salesforce/apex/PerformUserStoryAction.fetchCommits';

import { schema, constants } from './constants';

export default class WaitingPage extends NavigationMixin(LightningElement) {
    @api storyId;
    @api actionIds;
    @api snapshotId;
    @api actionType;

    @track updates = [];
    @track previousUpdates = [];

    schema = schema;
    constants = constants;

    fields = [];
    showSpinner = true;
    submitError = {
        isError: false,
        message: ''
    };

    _counter = 0;
    _commits = [];
    _sortedCommits = [];

    _subscription = {};
    _channelName = '/event/' + constants.namespace + 'Event__e';

    _operationsOrder = [constants.COMMIT_FILES, constants.FULL_PROFILES_PERMISSION_SETS, constants.DESTRUCTIVE_CHANGES];

    async connectedCallback() {
        try {
            await this._fetchDisplayFields();
            await this._commit();
            this._handleSubscribe();
            this._registerErrorListener();
        } catch (err) {
            this.submitError = {
                isError: true,
                message: err.body.message
            };
        }
    }

    navigateToRecordViewPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.storyId,
                actionName: 'view'
            }
        });
    }

    async _fetchDisplayFields() {
        this.fields = await getFieldsFromFieldSet({
            objectName: schema.USER_STORY_OBJECT,
            fieldSet: constants.FIELDSET
        });
    }

    async _commit() {
        this._commits = await fetchCommits({
            ids: this.actionIds
        });

        // Note: Sorting commits as per the Operation Order
        this._commits.forEach((commit) => {
            const operationIndex = this._operationsOrder.indexOf(commit[schema.GIT_OPERATION_FIELD]);
            this._sortedCommits[operationIndex] = commit.Id;
        });
        this._sortedCommits = this._sortedCommits.filter((commit) => commit != null);

        await startActionFlow({
            storyId: this.storyId,
            actionIds: this._sortedCommits,
            snapshotId: this.snapshotId,
            actionType: this.actionType
        });
    }

    _handleSubscribe() {
        const callback = this._handlePlatformEvent.bind(this);

        subscribe(this._channelName, -1, callback).then((response) => {
            this._subscription = response;
        });
    }

    _handlePlatformEvent = (response) => {
        const event = response.data.payload;

        if (this._isGitOperation(event)) {
            let notification = JSON.parse(event[schema.PAYLOAD_FIELD]);

            if (notification[schema.IS_FINISHED_FIELD]) {
                this._addLastUpdate(notification);
            } else {
                this._addUpdate(notification);
            }
            let rightPanelHeight = this.template.querySelector('.right-panel').scrollHeight;
            this.template.querySelector('.right-panel').scrollTop = rightPanelHeight;
        }
    };

    _addUpdate(notification) {
        if (this.updates.length) {
            this.updates[this.updates.length - 1].icon = constants.CHECK_ICON;
        } else {
            this.showSpinner = false;
            this._addSeperator(constants.START_ICON, constants.STARTED, this._counter + 1);
        }

        this.updates.push({ message: notification[schema.STATUS_FIELD] });
    }

    _addLastUpdate(notification) {
        this._counter += 1;
        let icon = constants.CHECK_ICON;

        if (notification[schema.IS_SUCCESS_FIELD]) {
            this.showSpinner = true;

            if (this.actionIds.length === this._counter) {
                this.showSpinner = false;
                this._handleUnsubscribe();
                setTimeout(() => {
                    this.navigateToRecordViewPage();
                }, 6000);
            }
        } else {
            icon = constants.WARNING_ICON;
            this._handleUnsubscribe();
        }

        this.updates[this.updates.length - 1].icon = icon;
        this.updates.push({ icon: icon, message: notification[schema.STATUS_FIELD] });
        this._refreshUpdates();
    }

    _refreshUpdates() {
        this._addSeperator(constants.FINISHED_ICON, constants.COMPLETED, this._counter);
        this.previousUpdates = this.previousUpdates.concat(this.updates);
        this.updates = [];
    }

    _addSeperator(icon, message, counter) {
        let currentCommit = this._commits.find((commit) => commit.Id == this._sortedCommits[counter - 1]);
        this.updates.push({ icon: icon, message: currentCommit[schema.GIT_OPERATION_FIELD] + ' ' + message });
    }

    _isGitOperation(event) {
        return (
            event[schema.PUBLISHER_CODE_FIELD] == constants.COPADO_BACKEND &&
            event[schema.TOPIC_URI_FIELD].startsWith(constants.TOPIC_URI + this.snapshotId + '/')
        );
    }

    _handleUnsubscribe() {
        unsubscribe(this._subscription, () => {});
    }

    _registerErrorListener() {
        onError((error) => {
            this.submitError = {
                isError: true,
                message: JSON.stringify(error)
            };
        });
    }
}