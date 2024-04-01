import { LightningElement, api, wire } from 'lwc';

import { reduceErrors } from 'c/copadocoreUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/copadoCorePubsub';
import { showToastSuccess } from 'c/copadocoreToastNotification';

import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { publish, MessageContext } from 'lightning/messageService';

import removeSelectedUserStoryBundleUserStories from '@salesforce/apex/UserStoryBundleUserStoriesTableCtrl.removeSelectedUserStories';

import Remove_USB_User_Stories_Confirmation from '@salesforce/label/c.Remove_USB_User_Stories_Confirmation';
import USB_user_stories_removed_successfully from '@salesforce/label/c.USB_user_stories_removed_successfully';
import Cancel from '@salesforce/label/c.Cancel';
import Confirm from '@salesforce/label/c.Confirm';
import Remove_USB_User_Stories from '@salesforce/label/c.Remove_USB_User_Stories';

export default class UserStoryBundleUserStoriesRemovalModal extends LightningElement {
    @api userStoryBundleBundleStoryIds;
    @api packageVersionId;

    showSpinner;
    label = {
        Cancel,
        Confirm,
        Remove_USB_User_Stories
    };
    communicationId = 'packageversionRecordPageAlerts';

    @wire(MessageContext)
    messageContext;

    @wire(CurrentPageReference) pageRef;

    get body() {
        return Remove_USB_User_Stories_Confirmation;
    }

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    handleCancel() {
        this.hide();
    }

    messageAlert(message, variant, dismissible) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId: this.communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }

    async handleConfirm() {
        this.showSpinner = true;

        try {
            const userStoryBundleBundleStoryIds = this.userStoryBundleBundleStoryIds;

            await removeSelectedUserStoryBundleUserStories({
                packageVersionId: this.packageVersionId,
                bundledStoryIds: userStoryBundleBundleStoryIds
            });
            showToastSuccess(this, { message: USB_user_stories_removed_successfully });
        } catch (error) {
            this.showSpinner = false;
            const errorMessage = reduceErrors(error);
            this.messageAlert(errorMessage, 'error', true);
        }

        this.showSpinner = false;

        this.hide();

        this.dispatchEvent(new CustomEvent('userstoriesremoved'));

        fireEvent(this.pageRef, 'userStoryRemovedEvent', this);
    }
}