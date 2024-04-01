({
    doInit : function(component, event, helper) {
        helper.setColumns(component);
    },

    handleCreateStep : function(component) {
        component.set("v.stepId", undefined);
        component.set("v.showEditModal", true);
    },

    handleRowAction : function(component, event) {
        const action = event.getParam("action");
        const stepId = event.getParam("stepId");

        component.set("v.stepId", stepId);

        if(action === "edit") {
            component.set("v.showEditModal", true);
        } else if(action === "delete") {
            component.find("job-steps-delete-popup").show();
        }
    },

    handleRecordDeleted : function(component) {
        component.find("job-steps-table").refresh();
    },

    closeEditModal : function(component) {
        component.set("v.showEditModal", false);
        component.find("job-steps-table").refresh();
    }
})