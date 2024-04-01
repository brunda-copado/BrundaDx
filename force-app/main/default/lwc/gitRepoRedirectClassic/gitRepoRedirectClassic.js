import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import copadoUtils from 'c/copadocoreUtils';

const schema = {
    NAMESPACE: copadoUtils.namespace
};

export default class GitRepoRedirectClassic extends NavigationMixin(LightningElement) { 
        _recordId;

   
        @api
        get recordId() {
            return this._recordId;
        }

        set recordId(recordId) {
            if (recordId !== this._recordId) {
                this._recordId = recordId;
            }
        }

    @api invoke() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/' + schema.NAMESPACE + 'viewGit?id='+this._recordId
            },
        });
  }
}