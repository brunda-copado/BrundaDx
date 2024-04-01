({
    publishRequest: function (component) {
        const uiSectionId = component.get('v.locationId');
        const requiredInformation = component.get('v.requiredInformation');
        const requiredLocationOnly = component.get('v.locationOnly');

        let requirement;
        if(requiredLocationOnly){
            requirement = 'requiringLocation';
        } else if (requiredInformation == undefined || requiredInformation.toLowerCase() === 'platform') {
            requirement = 'requiringPlatform';
        } else if (requiredInformation.toLowerCase() === 'test tool') {
            requirement = 'requiringTestTool';
        }

        const payload = {
            type: requirement,
            name: uiSectionId
        };

        component.find('messageChannel').publish(payload);
    },

    handleMessageSubscription: function (component, message) {
        const uiSectionId = component.get('v.locationId');
        const platform = message.getParam('platform');
        const testTool = message.getParam('testTool');
        const locationOnly = message.getParam('locationOnly');

        if (message != null && message.getParam('type') === uiSectionId && (platform != null || testTool != null || locationOnly)) {
            this.getComponentToRender(component, platform, testTool, uiSectionId);
        }
        if (message != null && message.getParam('action') === 'refresh') {
            component.set('v.body', {});
            this.publishRequest(component);
        }
    },

    getComponentToRender: function (component, platform, testTool, uiSectionId) {
        this.callApex(component, 'c.fetchUISection', { platform, testTool, uiSectionId }).then(
            $A.getCallback((uiSections) => {
                if(uiSections && uiSections.length > 0){
                    uiSections.forEach((uiSection) => 
                        this.renderDynamicComponent(component, uiSection)
                    )
                }
            })
        );
    },

    renderDynamicComponent: function (component, uiSection) {
        let componentName;
        if (uiSection) {
            componentName = uiSection.Component__c || uiSection.copado__Component__c;
        }

        component.set('v.body', {});
        if (componentName) {
            component.getEvent("showContent").fire();
            const recordId = component.get("v.recordId");
            $A.createComponent(componentName, { recordId }, (createdComponent, status, errorMessage) => {
                switch (status) {
                    case 'SUCCESS':
                        component.set('v.body', createdComponent);
                        break;
                    case 'ERROR':
                        console.error('Error: ' + errorMessage);
                        break;
                    default:
                }
            });
        }
    }
});