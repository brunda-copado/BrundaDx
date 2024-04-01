({
    doInit: function (component, event, helper) {
        component.set('v.loading', true);

        helper.init(component);
    },

    switchView: function (component, event, helper) {
        component.set('v.errorMessage', null);
        helper.switchView(component);
    },

    handleSave: function (component, event, helper) {
        component.set('v.errorMessage', null);
        const childComponent = component.get('v.componentBody') || {};

        if (helper.isValidConfig(component, childComponent)) {
            helper.saveStep(component, childComponent);
        }
    },

    handleCancel: function (component, event, helper) {
        helper.backToRecord(component);
    },

    toggleSection: function (component, event, helper) {
        const sectionAuraId = event.currentTarget.dataset.auraId;
        const sectionDiv = component.find(sectionAuraId).getElement();
        const sectionState = sectionDiv.getAttribute('class').search('slds-is-open');
        const classname = 'slds-section' + (sectionState == -1 ? ' slds-is-open' : ' slds-is-close');
        sectionDiv.setAttribute('class', classname);
    }
});