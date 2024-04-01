import { LightningElement, api, track } from 'lwc';
import getEnvironments from '@salesforce/apex/ContinuousDeliverySetupController.getEnvironments';
import { label } from './constants';

export default class ContinuousDeliverySetupEnvironmentSelections extends LightningElement {
    @api recordId;
    @api selectedStage;
    @api pipelineStages;
    @api isBackPromotion;
    @api configuration;

    @track environments = [];
    selectedEnvironments = [];
    error;
    label = label;

    get environmentSelectionData() {
        let result = {};
        result.header = this.isBackPromotion ? label.CD_Env_Selection_Header_For_Back_Promotion : label.CD_Env_Selection_Header_For_Promotion;
        result.body = this.isBackPromotion ? label.CD_Env_Selection_For_Back_Promotion : label.CD_Env_Selection_For_Promotion;
        result.sourceLabel = this.isBackPromotion ? label.Keep_manual_back_promotions : label.Keep_manual_promotions;
        result.selectedLabel = this.isBackPromotion ? label.Apply_automated_back_promotions : label.Apply_automated_promotions;

        return result;
    }

    connectedCallback() {
        this.getEnvironments();
    }

    async getEnvironments() {
        try {
            const stageData = this.pipelineStages.find(element => element.value === this.selectedStage);
            const recordIds = this.pipelineStages.slice(0, this.pipelineStages.indexOf(stageData) + 1).map(elem => elem.value);
            const recordId = this.recordId;
            const environments = await getEnvironments({ pipelineId: recordId, stageIds: recordIds });
            environments.forEach(environment => {
                this.environments.push({ label: environment.Name, value: environment.Name });
            });

            this.selectedEnvironments = this.isBackPromotion ? this.configuration.backpromotionSettings ? this.configuration.backpromotionSettings.selectedEnvironments : [] : this.configuration.promotionSettings ? this.configuration.promotionSettings.selectedEnvironments : [];    
        } catch (error) {
            console.error(error);
        }

        const spinner = new CustomEvent('stopspinner', {
            detail: true
        });

        this.dispatchEvent(spinner);
    }

    handleEnvironmentsSelected(event) {
        this.selectedEnvironments = event.detail.value;
    }

    handleNext() {
        if(!this.selectedEnvironments || this.selectedEnvironments.length === 0) {
            this.error = {
                title: label.Please_resolve_errors,
                message: label.Select_at_least_one_environment
            };
            return;
        }

        const next = new CustomEvent('getnextstep', {
            detail: {
                selectedEnvironments: this.selectedEnvironments
            }
        });

        this.dispatchEvent(next);
    }

    handlePrev() {
        const previous = new CustomEvent('getprevstep', {
            detail: true
        });

        this.dispatchEvent(previous);
    }
}