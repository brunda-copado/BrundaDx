import { LightningElement, api, track } from 'lwc';
import getStageConnections from '@salesforce/apex/ContinuousDeliverySetupController.getStageConnections';
import { namespace } from 'c/copadocoreUtils';
import { label } from './constants';

export default class ContinuousDeliverySetupPromotionConfiguration extends LightningElement {
    @api isBackPromotion;
    @api recordId;
    @api configuration;

    @track selectedStage;
    @track selectedRuleConditon;
    @track pipelineStages = [];

    label = label;

    get promotionSelectedEnvironment() {
        return this.configuration.promotionSettings && this.configuration.promotionSettings.selectedEnvironments
            ? this.configuration.promotionSettings.selectedEnvironments.length
            : 0;
    }

    get backPromotionSelectedEnvironment() {
        return this.configuration.backpromotionSettings && this.configuration.backpromotionSettings.selectedEnvironments
            ? this.configuration.backpromotionSettings.selectedEnvironments.length
            : 0;
    }

    get promotionConfigurationData() {
        let result = {};
        result.header = this.isBackPromotion ? label.CD_Setup_Back_Promotion_Header : label.CD_Setup_Promotion_Header;
        result.body = this.isBackPromotion ? label.CD_Setup_Back_Promotion_Body : label.CD_Setup_Promotion_Body;
        result.pathtext = this.isBackPromotion ? label.CD_Setup_Back_Promotion_Path_Text : label.CD_Setup_Promotion_Path_Text;

        return result;
    }

    get ruleConditonsOptions() {
        return [
            { label: label.CD_Setup_Configuration_Auto, value: 'auto' },
            { label: label.CD_Setup_Configuration_Manual, value: 'manual' }
        ];
    }

    get isRadioGroupDisabled() {
        return this.selectedStage ? false : true;
    }

    get isBackButtonEnabled() {
        return this.isBackPromotion;
    }

    get olTagClass() {
        return this.isBackPromotion
            ? 'slds-breadcrumb slds-list_horizontal slds-wrap right-to-left'
            : 'slds-breadcrumb slds-list_horizontal slds-wrap left-to-right';
    }

    connectedCallback() {
        this.getStageConnections();
    }

    async getStageConnections() {
        try {
            this.pipelineStages = [];
            const recordId = this.recordId;
            const stageConnections = await getStageConnections({ pipelineId: recordId });

            let connections = [];

            stageConnections.forEach(connection => {
                connections.push({
                    source: connection[namespace + 'Stage__c'],
                    target: connection[namespace + 'Next_Stage_Connection__c']
                        ? connection[namespace + 'Next_Stage_Connection__r'][namespace + 'Stage__c']
                        : ''
                });
            });
            const order = this._topologicalSort(connections);
            connections.sort(function (a, b) {
                return order.indexOf(a.source) - order.indexOf(b.source);
            });
            connections.forEach(connection => {
                const baseLiTagClass = this.isBackPromotion ? 'slds-breadcrumb__item right-to-left' : 'slds-breadcrumb__item left-to-right';
                const stage = stageConnections.find(element => element[namespace + 'Stage__c'] === connection.source);
                this.pipelineStages.push({
                    label: stage[namespace + 'Stage__r'][namespace + 'Display_Name__c'],
                    value: stage[namespace + 'Stage__c'],
                    className: baseLiTagClass
                });
            });

            const stageIds = this.isBackPromotion
                ? this.configuration.backpromotionSettings
                    ? this.configuration.backpromotionSettings.uptoStage
                    : ''
                : this.configuration.promotionSettings
                ? this.configuration.promotionSettings.uptoStage
                : '';
            this.selectedStage = stageIds ? this.pipelineStages.find(element => element.label === stageIds[stageIds.length - 1]).value : '';
            const selectedEnvironmentSize = this.isBackPromotion ? this.backPromotionSelectedEnvironment : this.promotionSelectedEnvironment;
            this.selectedRuleConditon = selectedEnvironmentSize === 0 ? 'auto' : 'manual';
            this._setStyleClassToStages();
        } catch (error) {
            console.error(error);
        }
        const spinner = new CustomEvent('stopspinner', {
            detail: true
        });

        this.dispatchEvent(spinner);
    }

    handleStagePatchClicked(event) {
        this.selectedStage = event.target.dataset.id;
        this._setStyleClassToStages();
    }

    handleRuleConditionChange(event) {
        this.selectedRuleConditon = event.detail.value;
    }

    handleNext() {
        const next = new CustomEvent('getnextstep', {
            detail: {
                selectedStage: this.selectedStage,
                pipelineStages: this.pipelineStages,
                selectedRuleConditon: this.selectedRuleConditon
            }
        });

        this.dispatchEvent(next);
    }

    handlePrev() {
        const stageIds = this.configuration.promotionSettings ? this.configuration.promotionSettings.uptoStage : '';
        this.selectedStage = stageIds ? this.pipelineStages.find(element => element.label === stageIds[stageIds.length - 1]).value : '';

        const previous = new CustomEvent('getprevstep', {
            detail: {
                selectedStage: this.selectedStage
            }
        });

        this.dispatchEvent(previous);
    }

    handleSkip() {
        const skip = new CustomEvent('skipthisstep', {
            detail: true
        });

        this.dispatchEvent(skip);
    }

    // PRIVATE

    _setStyleClassToStages() {
        const selectedClass = ' selected';
        const lastClass = ' last';
        if (!this.selectedStage) {
            return;
        }
        let stageNotFound = true;
        this.pipelineStages.forEach(stage => {
            stage.className = stage.className.replace(selectedClass, '');
            stage.className = stage.className.replace(lastClass, '');
            if (stageNotFound) {
                stage.className += selectedClass;
            }
            if (stage.value === this.selectedStage) {
                stage.className += lastClass;
                stageNotFound = false;
            }
        });
    }

    _topologicalSort(connections) {
        const sorted = [];
        const visited = new Set();

        const dfs = node => {
            visited.add(node);

            const connection = connections.find(conn => conn.source === node);
            if (connection) {
                const { target } = connection;
                if (!visited.has(target)) {
                    dfs(target);
                }
            }

            sorted.push(node);
        };

        connections.forEach(connection => {
            if (!visited.has(connection.source)) {
                dfs(connection.source);
            }
        });

        return sorted.reverse();
    }
}