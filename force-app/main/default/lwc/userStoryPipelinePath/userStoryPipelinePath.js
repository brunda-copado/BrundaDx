import { LightningElement, api, track, wire } from 'lwc';
import { reduceErrors } from 'c/copadocoreUtils';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/User_Story__c.Id';
import validate from '@salesforce/apex/UserStoryPipelinePathCtrl.validate';
import getDeploymentFlowSteps from '@salesforce/apex/UserStoryPipelinePathCtrl.getDeploymentFlowSteps';

export default class UserStoryPipelinePath extends LightningElement {
    @api recordId;
    @track alerts = [];
    @track steps = [];
    userStoryId = '';
    isLoaded = false;
    _isLicenseError = false;

    get hasAlerts() {
        return this.alerts && this.alerts.length ? true : false;
    }

    get hasSteps() {
        return this.steps && this.steps.length ? true : false;
    }

    get headerGridStyleClass() {
        return this.hasAlerts && this.hasSteps ? "header-grid slds-grid" : "slds-grid";
    }
    
    @wire(getRecord, { recordId: '$recordId', fields: [ID_FIELD] })
    getUserStoryRecord({ data, error }) {
        this._resetProperties();
        if (data) {
            this.userStoryId = getFieldValue(data, ID_FIELD);
        } else if (error) {
            console.error(error);
            this._handleError(error);
        }
    }

    @wire(validate, { userStoryId: '$userStoryId' })
    wiredValidate(response) {
        this.wiredResponse = response;
        let data = response.data;
        let error = response.error;
        if (data) {
            this._handleAlerts(data);
            if(!this._isLicenseError) {
                this._getDeploymentFlow();
            }
        } else if (error) {
            console.error(error);
            this._handleError(error);
        }
    }

    // TEMPLATE

    handleCloseAlert(event) {
        const index = event.target.dataset.index;
        this.alerts.splice(index, 1);
    }

    // PRIVATE

    _resetProperties() {
        this.userStoryId = '';
        this.isLoaded = false;
        this.alerts = [];
        this.steps = [];
    }

    async _getDeploymentFlow() {
        try {
            this.isLoaded = false;
            const data = await getDeploymentFlowSteps({ userStoryId: this.recordId });
            if (data && data.path && data.path.length) {
                this.steps = [];
                let count = 1;
                data.path.forEach((step) => {
                    step.id = count;
                    step.style = 'slds-tabs--path__item ' + step.style;
                    step.ariaControls = 'path-content-' + step.id;
                    this.steps.push(step);
                    count++;
                });
                this.isLoaded = true;
            } else if (data && data.alerts && data.alerts.length) {
                this._handleAlerts(data.alerts);
                this.isLoaded = true;
            }
        } catch (error) {
            console.error(error);
            this._handleError(error);
        }
    }

    _handleAlerts(alerts) {
        let count = 1;
        alerts.forEach((eachAlert) => {
            let alert = Object.assign({}, eachAlert);
            alert.id = count;
            this.alerts.push(alert);
            count++;
            if (!this._isLicenseError && alert.isBlocker) {
                this._isLicenseError = true;
                this.isLoaded = true;
            }
        });
    }

    _handleError(error) {
        const errorMessage = reduceErrors(error);
        const alert = { message: errorMessage, variant: 'error', dismissible: false, id: this.alerts.length + 1 };
        this.alerts.push(alert);
        this.isLoaded = true;
    }
}