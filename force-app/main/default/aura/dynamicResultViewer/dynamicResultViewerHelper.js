({
    init: function (component) {
        const resultId = component.get('v.recordId');

        const getComponentName = component.get("c.fetchResultViewerComponent");
        getComponentName.setParams({ recordId: resultId });

        getComponentName.setCallback(this, function (response) {
            const state = response.getState();

            if (state === "SUCCESS") {
                const componentName = response.getReturnValue();
                if (componentName !== null) {
                    component.getEvent("showContent").fire();
                    this.renderDynamicComponent(component, componentName);
                }
            } else if (state === "ERROR") {
                this.showErrors(component, response.getError());
            }
        });

        $A.enqueueAction(getComponentName);
    },

    showErrors: function (component, errors) {
        let errorMessage;
        if (errors && errors[0] && errors[0].message) {
            errorMessage = errors[0].message;
        } else {
            errorMessage = $A.get("$Label.c.Unexpected_Error_Occurred");
        }
        component.set("v.errorMessage", errorMessage);
    },

    renderDynamicComponent: function (component, componentName) {
        component.set('v.body', {});
        const recordId = component.get("v.recordId");
        if (componentName) {
            $A.createComponent(componentName, { recordId }, (resultViewerComponent, status, errorMessage) => {
                switch (status) {
                    case 'SUCCESS':
                        const body = component.get('v.body');
                        body.push(resultViewerComponent);
                        component.set('v.body', body);
                        break;
                    case 'ERROR':
                        component.set("v.errorMessage", errorMessage);
                        break;
                    default:
                }
            });
        }
    }
})