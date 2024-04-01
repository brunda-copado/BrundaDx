import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import checkPermissions from '@salesforce/apex/ContinuousDeliverySetupController.checkPermissions';
import getAutomationRules from '@salesforce/apex/ContinuousDeliverySetupController.getAutomationRules';
import { loadStyle } from "lightning/platformResourceLoader";
import modal from "@salesforce/resourceUrl/CD_LWC_QuickActionModalWidth";

export default class ContinuousDeliverySetup extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track pipelineStages = [];
    @track environments = [];
    @track selectedStage;
    @track summaryData = [];
    @track selectedRuleConditon;
    @track selectedEnvironments = [];

    ERROR_NAVIGATION = 8;

    configuration = { 
        'blockCommits' : false,
        'allowLocalEnvironmentBackPromotions' : false,
        'groupPromotionsBy' : 'Project__c',
        'submitSettings' : {
            'behavior' : 'manually',
            'cronExpression' : ''
        } 
    }
    showSpinner = true;
    currentStep = 0;
    errorMessage;

    get isConfigurationPreviewStep() {
        return this.currentStep === 0;
    }

    get isStartConfigurationStep() {
        return this.currentStep === 1;
    }
    
    get isPromotionConfigurationStep() {
        return this.currentStep === 2;
    }

    get isBackPromotionConfigurationStep() {
        return this.currentStep === 4;
    }
 
    get isPromotionEnvironmentSelectionStep() {
        return this.currentStep === 3;
    }

    get isBackPromotionEnvironmentSelectionStep() {
        return this.currentStep === 5;
    }

    get isDuplicatedRuleCheckStep() {
        return this.currentStep === 6;
    }

    get isConfigurationSummaryStep() {
        return this.currentStep === 7;
    }

    get isConfigurationErrorStep() {
        return this.currentStep === this.ERROR_NAVIGATION;
    }

    get isBackPromotionConfiguration() {
        return this.currentStep === 4 || this.currentStep === 5;
    }

    get promotionSelectedEnvironment() {
        return this.configuration.promotionSettings && this.configuration.promotionSettings.selectedEnvironments ? this.configuration.promotionSettings.selectedEnvironments.length : 0;
    }

    get backPromotionSelectedEnvironment() {
        return this.configuration.backpromotionSettings && this.configuration.backpromotionSettings.selectedEnvironments ? this.configuration.backpromotionSettings.selectedEnvironments.length : 0;
    }

    connectedCallback() {
        loadStyle(this, modal).then(() => {
            checkPermissions({ pipelineId: this.recordId }).then(() => {
                getAutomationRules({ pipelineId: this.recordId })
                .then((result) => {
                    this.summaryData = result;
                    if(this.summaryData.length === 0) {
                        this.handleNext();
                    } 
                }).catch(e => {
                    this.errorMessage = e.message || e.body?.message;
                    this.currentStep = this.ERROR_NAVIGATION;
                });
            }).catch(e => {
                this.errorMessage = e.message || e.body?.message;
                this.currentStep = this.ERROR_NAVIGATION;
            });
        });
    }

    handleNext(event) {
        this.showSpinner = true;
        this.configuration = event && event.detail.configuration ? event.detail.configuration : this.configuration;
        this.selectedStage = event && event.detail.selectedStage ? event.detail.selectedStage : this.selectedStage;
        this.pipelineStages = event && event.detail.pipelineStages ? event.detail.pipelineStages : this.pipelineStages;
        this.selectedRuleConditon = event && event.detail.selectedRuleConditon ? event.detail.selectedRuleConditon : this.selectedRuleConditon;
        this.selectedEnvironments = event && event.detail.selectedEnvironments ? event.detail.selectedEnvironments : this.selectedEnvironments;

        if(this.currentStep >= 2 && this.currentStep < 4) {
            this.forwardPromotionsSetting();
        } else if(this.currentStep >= 4) {
            this.backPromotionsSetting();
        }
        
        if((this.isPromotionConfigurationStep || this.isBackPromotionConfigurationStep) && this.selectedRuleConditon === 'auto') {
            this.currentStep++;
        }
        this.currentStep++;

        if(this.isConfigurationSummaryStep) {
            this.prepareSummaryData();
        }
    }
 
    handlePrev(event) {
        this.showSpinner = true;
        this.selectedStage = event && event.detail.selectedStage ? event.detail.selectedStage : this.selectedStage;
        if(this.isConfigurationSummaryStep) {
            this.currentStep--;
        }
        if(this.isConfigurationSummaryStep || this.isDuplicatedRuleCheckStep || this.isBackPromotionConfigurationStep) {
            const selectedEnvironmentSize = this.isDuplicatedRuleCheckStep ? this.backPromotionSelectedEnvironment : this.promotionSelectedEnvironment;
            if(selectedEnvironmentSize === 0) {
                this.currentStep--;
            }
        }
        this.currentStep--;
    } 

    forwardPromotionsSetting() {
        const promotionSettings = this.configuration.promotionSettings ? this.configuration.promotionSettings : {};
        if(this.selectedStage) {
            const stageData = this.pipelineStages.find(element => element.value === this.selectedStage);
            const stageId = this.pipelineStages.slice(0, this.pipelineStages.indexOf(stageData) + 1).map(elem => elem.label);
            promotionSettings.uptoStage = stageId
        }  
        promotionSettings.selectedEnvironments = this.isPromotionEnvironmentSelectionStep ? this.selectedEnvironments : this.selectedRuleConditon === 'manual' ? promotionSettings.selectedEnvironments : [];
        this.configuration.promotionSettings = promotionSettings;
    }

    backPromotionsSetting() {
        const backpromotionSettings = this.configuration !== null && this.configuration.backpromotionSettings ? this.configuration.backpromotionSettings : {};
        if(this.selectedStage) {
            const stageData = this.pipelineStages.find(element => element.value === this.selectedStage);
            const stageId = this.pipelineStages.slice(0, this.pipelineStages.indexOf(stageData) + 1).map(elem => elem.label);
            backpromotionSettings.uptoStage = stageId
        }   
        backpromotionSettings.selectedEnvironments =  this.isBackPromotionEnvironmentSelectionStep ? this.selectedEnvironments : this.selectedRuleConditon === 'manual' ? backpromotionSettings.selectedEnvironments : [];
        this.configuration.backpromotionSettings = backpromotionSettings;
    }

    handleSkipStep() {
        this.showSpinner = true;
        
        if(this.isPromotionConfigurationStep) {
            this.configuration.promotionSettings = {};
        } else if(this.isBackPromotionConfigurationStep) {
            this.configuration.backpromotionSettings = {};
        }
        
        this.currentStep = this.currentStep + 2;
        if(this.isConfigurationSummaryStep) {
            this.prepareSummaryData();
        }
    }

    prepareSummaryData() {
        this.summaryData = [];
        const stageData = {
            'promotion' : this.configuration.promotionSettings && this.configuration.promotionSettings.uptoStage ? this.configuration.promotionSettings.uptoStage.join() : '',
            'backPromotion' : this.configuration.backpromotionSettings && this.configuration.backpromotionSettings.uptoStage ? this.configuration.backpromotionSettings.uptoStage.join() : '',
        }
        
        const environmentData = {
            'promotion' : this.configuration.promotionSettings && this.configuration.promotionSettings.selectedEnvironments && this.configuration.promotionSettings.selectedEnvironments.length !== 0 ? this.configuration.promotionSettings.selectedEnvironments.join() : 'All',
            'backPromotion' : this.configuration.backpromotionSettings && this.configuration.backpromotionSettings.selectedEnvironments && this.configuration.backpromotionSettings.selectedEnvironments.length !== 0 ? this.configuration.backpromotionSettings.selectedEnvironments.join() : 'All',
        }

        if(this.configuration.promotionSettings && this.configuration.promotionSettings.uptoStage) {
            const promotionRecord = {
                'Name' : 'Automated Promotion', 
                'Stages' : stageData.promotion, 
                'Environments' : environmentData.promotion
            }
            this.summaryData.push(promotionRecord);
        }
        
        if(this.configuration.backpromotionSettings && this.configuration.backpromotionSettings.uptoStage) {
            const backPromotionRecord = {
                'Name' : 'Automated Back-promotion', 
                'Stages' : stageData.backPromotion, 
                'Environments' : environmentData.backPromotion
            }
            this.summaryData.push(backPromotionRecord);
        }
    }
    
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    stopSpinner() {
        this.showSpinner = false;
    }

    enableSpinner() {
        this.showSpinner = true;
    }
}