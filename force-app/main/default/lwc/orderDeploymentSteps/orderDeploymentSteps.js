import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/copadocoreUtils';
import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';

import getSteps from '@salesforce/apex/OrderDeploymentStepsController.getFilteredDeploymentSteps';
import { labels, schema, tableColumns } from './constants';

export default class OrderDeploymentSteps extends LightningElement {
    @api parentId;
    @api isValidation = false;

    label = labels;
    columns = tableColumns;
    beforeSteps = [];
    afterSteps = [];
    loading = false;

    get beforeStepsEmpty() {
        return this.beforeSteps.length === 0;
    }

    get afterStepsEmpty() {
        return this.afterSteps.length === 0;
    }

    get beforeAndAfterStepsEmpty() {
        return this.beforeSteps.length === 0 && this.afterSteps.length === 0;
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        this.initSteps();
        registerListener('dropRowEvent', this.handleDragAndDrop, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    async initSteps() {
        this.loading = true;

        try {
            if (this.parentId) {
                const parentId = this.parentId;
                const isValidation = this.isValidation;
                const data = await getSteps({ parentId, isValidation });

                if (data) {
                    data.forEach(step => {
                        let userStory = step[schema.USER_STORY_FIELD.fieldApiName.replace('__c', '__r')];
                        step.userStoryLink = '/' + userStory[schema.USER_STORY_ID_FIELD.fieldApiName];
                        step.userStoryName = userStory[schema.USER_STORY_NAME_FIELD.fieldApiName];
                        step.userStoryTitle = userStory[schema.USER_STORY_TITLE_FIELD.fieldApiName];

                        if (step[schema.EXECUTION_SEQUENCE_FIELD.fieldApiName] === 'after') {
                            this.afterSteps.push(step);
                        } else {
                            this.beforeSteps.push(step);
                        }
                    });
                }
            }
        } catch (error) {
            this.showToast(this.label.Deployment_Steps + ' ' + this.label.Error_Value, reduceErrors(error), 'error');
        }

        this.loading = false;
    }

    @api getDeploymentStepIds() {
        let result = [];

        this.beforeSteps.forEach(step => {
            result.push(step.Id);
        });

        this.afterSteps.forEach(step => {
            result.push(step.Id);
        });
        return result;
    }

    handleRowAction(event) {
        try {
            const dataRow = event.detail.row;
            const { Id } = event.detail.row;
            if (dataRow[schema.EXECUTION_SEQUENCE_FIELD.fieldApiName] === 'after') {
                this.afterSteps = this.afterSteps.filter(record => record.Id !== Id);
            } else {
                this.beforeSteps = this.beforeSteps.filter(record => record.Id !== Id);
            }
        } catch (error) {
            this.showToast(this.label.Deployment_Steps + ' ' + this.label.Error_Value, reduceErrors(error), 'error');
        }
    }

    handleDragAndDrop(event) {
        try {
            const oldIndex = event.draggingBeginsAt;
            const newIndex = event.draggingEndsAt;
            const source = event.sourceName;
            const data = source === 'before-steps' ? [...this.beforeSteps] : [...this.afterSteps];

            let i;
            const targetRow = this.row(source, oldIndex);

            if (oldIndex < newIndex) {
                for (i = oldIndex; i < newIndex; i++) {
                    data[i] = this.swappedRow(this.row(source, i + 1), i);
                }
            } else {
                for (i = oldIndex; i > newIndex; i--) {
                    data[i] = this.swappedRow(this.row(source, i - 1), i);
                }
            }

            data[newIndex] = this.swappedRow(targetRow, newIndex);

            if (source === 'before-steps') {
                this.beforeSteps = data;
            } else {
                this.afterSteps = data;
            }
        } catch (error) {
            this.messageAlert = { variant: 'error', message: this.label.Error_Value + ' ' + reduceErrors(error) };
        }
    }

    row(source, index) {
        return source === 'before-steps' ? this.beforeSteps[index] : this.afterSteps[index];
    }

    swappedRow(row, index) {
        return Object.assign(JSON.parse(JSON.stringify(row)), { [schema.ORDER_FIELD.fieldApiName]: index + 1 });
    }

    showToast(title, message, variant = 'error') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}