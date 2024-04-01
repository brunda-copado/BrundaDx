import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { reduceErrors, formatLabel } from 'c/copadocoreUtils';

import { label } from './constants';

import getContext from '@salesforce/apex/AppDetectorController.getContext';
import updateDefaultAppForUser from '@salesforce/apex/AppDetectorController.updateDefaultAppForUser';

export default class AppDetector extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api platformFieldApiName;
    @api warningMessage;

    label = label;

    isWrongContext = false;
    get message() {
        return formatLabel(this.warningMessage, [this._platform]);
    }

    _platform;
    _expectedAppId;

    @wire(getContext, { recordId: '$recordId', platformFieldApiName: '$platformFieldApiName' })
    wiredGetContext({ data, error }) {
        if (data) {
            if (data.expectedAppId && data.currentAppId !== data.expectedAppId) {
                this.isWrongContext = true;
                this._platform = data.platform;
                this._expectedAppId = data.expectedAppId;
            }
        } else if (error) {
            const errorMessage = reduceErrors(error);
            console.error(errorMessage);
        }
    }

    changeApp() {
        // NOTE: using NavigationMixin.Navigate will not update the new default app
        // so we need to manually update the new default app otherwise the context detection will not work
        updateDefaultAppForUser({ newAppId: this._expectedAppId });

        // NOTE: NavigationMixin.Navigate must be called in the same call-stack as event handler, so we can't
        // wait if default app has been updated successfully
        this[NavigationMixin.Navigate]({
            type: 'standard__app',
            attributes: {
                appTarget: this._expectedAppId,
                pageRef: {
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: this.objectApiName,
                        actionName: 'view'
                    }
                }
            }
        });
    }
}