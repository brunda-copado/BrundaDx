import { LightningElement, api } from 'lwc';

export default class StatusIndicator extends LightningElement {
    @api status;
    @api message;

    //GETTERS

    get inProgress() {
        return this.status === 'In Progress';
    }

    get notExecutable() {
        return this.status === 'Not Executable';
    }

    get executedStatus() {
        return this.status !== 'Not Executable' && this.status !== 'In Progress';
    }

    get iconName() {
        const iconByStatus = {
            Success: 'utility:success',
            Failed: 'utility:clear',
            'Not Started': 'utility:clock',
            Cancelled: 'utility:ban',
            'Not Executable': 'utility:error'
        };

        return iconByStatus[this.status];
    }

    get iconVariant() {
        const variantByStatus = {
            Success: 'success',
            Failed: 'error',
            'Not Executable': 'error'
        };

        return variantByStatus[this.status];
    }

    toggleTooltip() {
        this.template.querySelectorAll('.slds-popover').forEach((tooltip) => tooltip.classList.toggle('slds-hide'));
    }
}