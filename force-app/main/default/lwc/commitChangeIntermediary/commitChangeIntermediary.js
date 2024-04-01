import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { namespace } from 'c/copadocoreUtils';

import getCommitPageName from '@salesforce/apex/CommitChangeIntermediaryCtrl.getCommitPageNameFromSettings';

export default class CommitChangeIntermediary extends NavigationMixin(LightningElement) {
    defaultPageName = namespace + 'User_Story_Commit';
    @api recordId;

    @api invoke() {
        this.getcommitPage();
    }

    getcommitPage() {
        getCommitPageName({ userstoryId: this.recordId })
            .then(data => {
                this.navigateToCommitPage(data);
            })
            .catch(() => {
                this.navigateToCommitPage(this.defaultPageName);
            });
    }

    navigateToCommitPage(pageName) {
        const parameters = {};
        parameters[`${namespace || 'c__'}recordId`] = this.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: pageName
            },
            state: parameters
        });
    }
}