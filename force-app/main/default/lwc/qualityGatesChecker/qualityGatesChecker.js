import { LightningElement, api } from 'lwc';

import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';

import QUALITY_GATE_RULES_CHECK from '@salesforce/label/c.Quality_Gate_Rules_Check';
import QUALITY_GATE_RULES_CHECK_BUTTON from '@salesforce/label/c.Quality_Gate_Rules_Check_Button';

import checkQualityGates from '@salesforce/apex/QualityGatesCheckerCtrl.checkQualityGates';
import deactivateQualityGates from '@salesforce/apex/QualityGatesCheckerCtrl.deactivateQualityGates';
import activateQualityGates from '@salesforce/apex/QualityGatesCheckerCtrl.activateQualityGates';

export default class QualityGatesChecker extends LightningElement {
    @api recordId;

    qualityGateRules = [];
    hasPermission = false;
    fixed = false;
    loading = false;

    get showWarning() {
        return this.qualityGateRules.length > 0 && !this.fixed;
    }

    get showButton() {
        return this.hasPermission;
    }

    get message() {
        return this.showButton ? QUALITY_GATE_RULES_CHECK.substr(0, QUALITY_GATE_RULES_CHECK.indexOf('.') + 1) : QUALITY_GATE_RULES_CHECK;
    }

    get buttonLabel() {
        return QUALITY_GATE_RULES_CHECK_BUTTON;
    }

    async connectedCallback() {
        try {
            this.loading = true;
            const result = await checkQualityGates({ recordId: this.recordId });
            this.hasPermission = result.hasPermission;
            this.qualityGateRules = result.qualityGateRules;
            this.loading = false;
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }

    async fixQualityGateRules() {
        try {
            this.loading = true;
            await deactivateQualityGates({ qualityGateRules: this.qualityGateRules });
            await activateQualityGates({ qualityGateRules: this.qualityGateRules });
            this.fixed = true;
            this.loading = false;
        } catch (error) {
            const errorMessage = reduceErrors(error);
            showToastError(this, { message: errorMessage });
        }
    }
}