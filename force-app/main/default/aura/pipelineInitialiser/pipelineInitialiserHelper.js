({
    init: function (component) {
        component.set("v.loading", true);

        const getComponentName = component.get("c.getInitializationComponentName");
        getComponentName.setParams({
            pipelineId: component.get('v.recordId')
        });

        getComponentName.setCallback(this, function (response) {
            const state = response.getState();

            if (state === "SUCCESS") {
                const componentName = response.getReturnValue();
                component.set("v.componentNameNotFound", !Boolean(componentName));

                if (componentName !== null) {
                    this.renderDynamicComponent(component, componentName);
                }
            } else if (state === "ERROR") {
                component.set("v.componentNameNotFound", true);
                this.showErrors(component, response.getError());
            }
        });

        $A.enqueueAction(getComponentName);
        component.set("v.loading", false);
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
            $A.createComponent(componentName, { recordId }, (configurationComponent, status, errorMessage) => {
                switch (status) {
                    case 'SUCCESS':
                        component.set('v.body', configurationComponent);
                        break;
                    default:
                }
            });
        }
    }
})