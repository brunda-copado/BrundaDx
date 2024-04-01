({
    init: function (component) {
        const recordId = component.get('v.recordId');

        if (recordId != null) {
            const getComponentName = component.get("c.getComponentName");
            getComponentName.setParams({ recordId: recordId });

            getComponentName.setCallback(this, function (response) {
                const state = response.getState();

                if (state === "SUCCESS") {
                    const componentName = response.getReturnValue();
                    if (componentName !== null) {
                        this.renderDynamicComponent(component, componentName);
                    }
                }
            });

            $A.enqueueAction(getComponentName);
        }

    },

    handleMessageSubscription: function (component, event) {
        if (event.getParam('action') === 'refresh') {
            component.set('v.body', {});
            this.init(component);
        }
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