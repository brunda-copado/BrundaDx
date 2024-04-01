({
    setValidationSetting: function (cmp) {
        const getValidationSetting = cmp.get('c.getValidationSetting');

        getValidationSetting.setParams({ recordId: cmp.get('v.recordId') });

        getValidationSetting.setCallback(this, response => {
            if (response.getState() === 'SUCCESS') {
                cmp.set('v.validationSetting', response.getReturnValue());
            }

            this.hideSpinner(cmp);
        });

        $A.enqueueAction(getValidationSetting);
    },
    validate: function (cmp) {
        this.showSpinner(cmp);
        const validateChanges = cmp.get('c.validateChanges');
        const deploymentSteps = cmp.find('orderDeploymentSteps').getDeploymentStepIds();
        validateChanges.setParams({ recordId: cmp.get('v.recordId'), deploymentStepIds: deploymentSteps });

        validateChanges.setCallback(this, response => {
            if (response.getState() === 'SUCCESS') {
                this.showToast(cmp, 'success', $A.get('$Label.c.ValidationSuccessful'));
                this.redirectTo(response.getReturnValue());
            } else {
                this.showToast(cmp, 'error', $A.get('$Label.c.ValidateError'), response.getError()[0].message);
            }

            this.hideSpinner(cmp);
            this.closeModal();
        });

        $A.enqueueAction(validateChanges);
    },
    hideSpinner: function (cmp) {
        cmp.set('v.loading', false);
    },
    showSpinner: function (cmp) {
        cmp.set('v.loading', true);
    },
    showToast: function (cmp, variant, title, message) {
        cmp.find('notifLib').showToast({ variant, title, message });
    },
    closeModal: function () {
        $A.get('e.force:closeQuickAction').fire();
    },
    redirectTo: function (recordId) {
        $A.get('e.force:navigateToSObject').fire({ recordId });
    }
});