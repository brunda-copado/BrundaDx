import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { showToastError, showToastInfo } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import { labels, schema, constants } from './constants';

export default class SprintMetrics extends LightningElement {
    @api recordId;
    @api title;
    @api legendPosition;
    @api plannedVelocityField;
    @api actualVelocityField;

    isLoaded = false;
    isLoading = true;
    isCollapsed = false;
    canBeFreeze = false;
    burnDownComplete = false;
    burnUpComplete = false;
    showEmptyIllustration = false;
    labels = labels;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.STATUS_FIELD, schema.START_DATE_FIELD, schema.END_DATE_FIELD] })
    wiredSprint({ error, data }) {
        
        if (error) {
            const message = reduceErrors(error);
            showToastError(this, { message });
        } else if (data) {
            const status = getFieldValue(data, schema.STATUS_FIELD);
            const startDate = getFieldValue(data, schema.START_DATE_FIELD);
            const endDate = getFieldValue(data, schema.END_DATE_FIELD);
            this.showEmptyIllustration = (startDate == null || endDate == null);
            this.isLoaded = !this.showEmptyIllustration;
            this.canBeFreeze = (status === constants.SPRINT_STATUS_COMPLETED);
            if (this.canBeFreeze) {
                showToastInfo(this, { title: labels.SPRINT_FREEZED_LABEL });
            }
        }
    }

    connectedCallback() {
        this.objectName = schema.SPRINT_OBJECT.objectApiName;
        this.isLoaded = true;
        this.isLoading = false;
    }

    handleFreeze() {
        this.isLoading = true;
        this.template.querySelector('c-sprint-metrics-burn-up').freeze();
        this.template.querySelector('c-sprint-metrics-burn-down').freeze();
    }

    handleCollapse() {
        this.isCollapsed = true;
    }

    handleUncollapse() {
        this.isCollapsed = false;
    }

    handleBurnDownComplete() {
        this.burnDownComplete = true;

        if (this.burnDownComplete && this.burnUpComplete) {
            this.isLoading = false;
        }
    }

    handleBurnUpComplete() {
        this.burnUpComplete = true;

        if (this.burnDownComplete && this.burnUpComplete) {
            this.isLoading = false;
        }
    }
}