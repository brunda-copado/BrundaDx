import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getClassicURL from '@salesforce/apex/NewSnapshotIntermediaryController.getClassicURL';
import { schema } from './constants';

export default class EditGitSnapshotIntermediaryRedirect extends NavigationMixin(LightningElement) {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [schema.PIPELINE_FIELD] })
    wiredRecord(result) {
        const { error, data } = result;
        if (data) {
            const pipeline = getFieldValue(data, schema.PIPELINE_FIELD);
            if (pipeline) {
                this.navigateToLightningPage();
            } else {
                this.navigateToVFPage();
            }
        } else if (error) {
            this.navigateToVFPage();
        }
    }

    navigateToLightningPage() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: schema.SNAPSHOT_OBJECT.objectApiName,
                recordId: this.recordId,
                actionName: 'view'
            }
        }).then(url => {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: schema.SNAPSHOT_OBJECT.objectApiName,
                    recordId: this.recordId,
                    actionName: 'edit'
                },
                state: {
                    nooverride: 1,
                    navigationLocation: 'DETAIL',
                    backgroundContext: url
                }
            });
        });
    }

    navigateToVFPage() {
        getClassicURL().then(classicURI => {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: classicURI + '?Id=' + this.recordId
                }
            })
        });
    }
}