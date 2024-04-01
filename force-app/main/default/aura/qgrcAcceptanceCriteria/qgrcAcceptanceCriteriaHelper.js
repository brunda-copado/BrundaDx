({
    init: function (component) {
        const qgrcId = component.get('v.recordId');

        const checkForUiSection = component.get('c.checkForUiSection');
        checkForUiSection.setParams({ qualityGateConditionId: qgrcId });

        checkForUiSection.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                const availableUISection = response.getReturnValue();
                component.set('v.acceptanceCriteriaFound', availableUISection);
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), 'Error');
            }
            component.set('v.loading', false);
        });

        $A.enqueueAction(checkForUiSection);
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