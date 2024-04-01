import { LightningElement } from 'lwc';
import { label } from './constants';

export default class ContinuousDeliverySetupStart extends LightningElement {
    label = label;
    isRendered = false;

    renderedCallback() {
        if(!this.isRendered) {
            this.isRendered = true;

            const spinner = new CustomEvent('stopspinner', {
                detail: true
            });
    
            this.dispatchEvent(spinner);
        }
    }
    
    handleNext() {
        // Create Event
        const next = new CustomEvent('getnextstep', {
            detail: { 
                configuration : {
                    'blockCommits' : false,
                    'allowLocalEnvironmentBackPromotions' : false,
                    'groupPromotionsBy' : 'Project__c',
                    'submitSettings' : {
                        'behavior' : 'manually',
                        'cronExpression' : ''
                    } 
                }
            }
        });

        // Dispatches the event
        this.dispatchEvent(next);
    }
}