({
    init: function (component) {
        const activeSections = [];
        const testId = component.get('v.recordId');

        const checkForUiSections = component.get('c.checkForUiSections');
        checkForUiSections.setParams({ testId: testId });

        checkForUiSections.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                const availableUISections = response.getReturnValue();
                component.set('v.generalSettingsFound', availableUISections[0]);
                component.set('v.acceptanceCriteriaFound', availableUISections[1]);
                if (availableUISections[0]) {
                    activeSections.push('generalSettings');
                }
                if (availableUISections[1]) {
                    activeSections.push('acceptanceCriteria');
                }
                component.set('v.activeSections', activeSections);
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), 'Error');
            }
            component.set('v.loading', false);
        });

        $A.enqueueAction(checkForUiSections);
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