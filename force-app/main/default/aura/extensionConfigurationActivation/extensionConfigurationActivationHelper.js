({
    init: function (component) {
        const extensionId = component.get('v.recordId');
        const activationResult = component.get('c.requiresActivationLogic');
        activationResult.setParams({ extensionConfigId: extensionId });

        activationResult.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                const requiresAdditionalData = response.getReturnValue();
                component.set('v.requiresAdditionalData', requiresAdditionalData);
                if (!requiresAdditionalData) {
                    this.showToast('Success', 'success', $A.get('$Label.c.ExtensionSuccessfullyActivated'));
                    $A.get('e.force:closeQuickAction').fire();
                    $A.get('e.force:refreshView').fire();
                }
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), 'Error');
            }
        });

        $A.enqueueAction(activationResult);
    },

    showToast: function (title, type, message) {
        $A.get('e.force:showToast').fire({ title, type, message });
    },

    showErrors: function (component, errors, label) {
        let errorMessage;
        if (errors && errors[0] && errors[0].message) {
            errorMessage = label + errors[0].message;
        } else {
            errorMessage = label + $A.get('$Label.c.Unexpected_Error_Occurred');
        }
        component.set('v.errorMessage', errorMessage);
    }
});