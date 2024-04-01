import { LightningElement, api, wire } from 'lwc';
import { reduceErrors } from 'c/copadocoreUtils';
import { CloseActionScreenEvent } from 'lightning/actions';
import { showToastError, showToastSuccess } from 'c/copadocoreToastNotification';
import { CurrentPageReference } from 'lightning/navigation';
import getCompletedUserStories from '@salesforce/apex/ExcludeCompletedUserStoriesCBMCtrl.getCompletedUserStories';
import updateUserStoryFields from '@salesforce/apex/ExcludeCompletedUserStoriesCBMCtrl.updateUserStoryFields';
import { label } from './constants';

const columns = [
    { label: label.Name, fieldName: 'Name', type: 'text' },
    { label: label.ExcludeFromPipelines, fieldName: 'Exclude_From_CBM__c', type: 'boolean' },
    { label: label.ExcludeFromOverlapAwareness, fieldName: 'Stop_Indexing_Metadata__c', type: 'boolean' }
];
export default class ExcludeCompletedUserStoriesCBM extends LightningElement {
    recordId;
    data;
    isLoading = false;
    @api columns = columns;
    label = label;

    @wire(CurrentPageReference)
    getParameters(pageReference) {
        if (pageReference && pageReference.state) {
            this.recordId = pageReference.state.recordId;
        }
    }

    connectedCallback() {
        this._retreiveUserStories();
    }

    async _retreiveUserStories() {
        this.isLoading = true;
        try {
            this.data = await getCompletedUserStories({ recordId: this.recordId });
            this.isLoading = false;
        } catch (error) {
            this.data = undefined;
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    get title() {
        return label.ExcludeStoryCBMTitle;
    }

    async save() {
        this.isLoading = true;
        const selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();
        let selectedRowsSet = new Set();
        selectedRecords.forEach(element => {
            selectedRowsSet.add(element.Id);
        });

        try {
            await updateUserStoryFields({ result: JSON.stringify([...selectedRowsSet]), recordId: this.recordId });
            showToastSuccess(this, {
                message: label.UserStoriesUpdatedSuccessfully
            });
            this.dispatchEvent(new CloseActionScreenEvent());
            this.isLoading = false;
        } catch (error) {
            showToastError(this, { message: reduceErrors(error) });
        }
    }

    cancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}