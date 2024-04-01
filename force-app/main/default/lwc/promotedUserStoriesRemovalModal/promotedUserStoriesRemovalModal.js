import { LightningElement, api, wire } from 'lwc';

import { reduceErrors, formatLabel } from 'c/copadocoreUtils';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/copadoCorePubsub';
import { showToastSuccess } from 'c/copadocoreToastNotification';

import removeSelectedPromotedUserStories from '@salesforce/apex/PromotedUserStoriesDatatableController.removeSelectedPromotedUserStories';

import { label } from './constants';

export default class PromotedUserStoriesRemovalModal extends LightningElement {
    @api promotedUserStoryIds;
    @api contentDocumentId;

    communicationId = 'promotionRecordPageAlerts';
    modalCommunicationId = 'modalAlerts';

    label = label;

    @wire(CurrentPageReference) pageRef;

    @wire(MessageContext)
    messageContext;

    get body() {
        let rowCount = this.promotedUserStoryIds ? this.promotedUserStoryIds?.length : 0;
        return formatLabel(label.Remove_Promoted_User_Stories_Confirmation, [rowCount]);
    }

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    renderedCallback() {
        if (this.contentDocumentId) {
            this._messageAlert(label.Remove_Promoted_User_Stories_Ignored_Changes_Warning, 'warning', false, this.modalCommunicationId);
        }
    }

    handleCancel() {
        this.hide();
    }

    async handleConfirm() {
        this.hide();

        try {
            const promotedUserStoryIds = this.promotedUserStoryIds;
            const contentDocumentId = this.contentDocumentId;
            await removeSelectedPromotedUserStories({ promotedUserStoryIds, contentDocumentId });
            showToastSuccess(this, { message: label.Promoted_user_stories_removed_successfully });
        } catch (error) {
            this.messageAlert(label.Error_while_removing_promoted_user_stories + ' ' + reduceErrors(error), 'error', false, this.communicationId);
        }

        this.dispatchEvent(new CustomEvent('promoteduserstoriesremoved'));

        fireEvent(this.pageRef, 'userStoryRemovedEvent', this);
    }

    // PRIVATE

    _messageAlert(message, variant, dismissible, communicationId) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }
}