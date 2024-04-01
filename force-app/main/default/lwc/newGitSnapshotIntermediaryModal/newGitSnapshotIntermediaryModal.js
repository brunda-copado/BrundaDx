import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getClassicURL from '@salesforce/apex/NewSnapshotIntermediaryController.getClassicURL';
import userHasSnapshotPermission from '@salesforce/apex/NewSnapshotIntermediaryController.userHasSnapshotPermission';
import { labels, object, options, selectedValue } from './constants';

export default class NewGitSnapshotIntermediaryModal extends NavigationMixin(LightningElement) {
    label = labels;
    selectedOption = selectedValue.classic;

    get options() {
        return options;
    }

    get bodyTexts() {
        return this.label.NEW_GIT_SNAPSHOT_BODY_MESSAGE.split('~');
    }

    handleEditCancel() {
        this.template.querySelector('c-copadocore-modal').hide();
        this.navigateToListView();
    }

    handleRadioGroupOnChange(event) {
        event.preventDefault();
        event.stopPropagation();
        this.selectedOption = event.detail.value;
    }

    navigateEditForm() {
        if (this.selectedOption === selectedValue.classic) {
            getClassicURL()
                .then(classicURI => {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: classicURI
                        }
                    }).then(generatedUrl => {
                        window.open(generatedUrl, '_self');
                    });
                })
                .catch(error => {
                    console.error(error);
                });
        } else {
            this.handleEditCancel();
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: object.SNAPSHOT_OBJECT.objectApiName,
                    actionName: 'new'
                },
                state: {
                    nooverride: '1',
                    navigationLocation: 'LIST_VIEW',
                    backgroundContext: '/lightning/o/' + object.SNAPSHOT_OBJECT.objectApiName + '/list?filterName=Recent'
                }
            });
        }
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: object.SNAPSHOT_OBJECT.objectApiName,
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    renderedCallback() {
        userHasSnapshotPermission()
            .then(result => {
                if (result) {
                    const newGitSnapshotModal = this.template.querySelector('c-copadocore-modal');
                    newGitSnapshotModal.show();
                } else {
                    this.navigateEditForm();
                }
            })
            .catch(error => {
                console.error(error);
            });
    }
}