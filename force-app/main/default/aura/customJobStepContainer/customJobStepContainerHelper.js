({
    setColumns: function (component) {
        const getNamespace = component.get("c.getNamespace");

        getNamespace.setCallback(this, function (response) {
            const state = response.getState();

            if (state === "SUCCESS") {
                const namespace = response.getReturnValue();
                component.set("v.namespace", namespace);
                component.set("v.columns", this.columns(component));
            } else if (state === "ERROR") {
                this.showErrors(response.getError(), $A.get("$Label.c.Error_Retrieving_Namespace"));
            }
        });

        $A.enqueueAction(getNamespace);
    },

    columns: function (component) {
        const namespace = component.get("v.namespace");
        const parent = component.get("v.sObjectName");

        let columns = [
            {
                label: $A.get("$Label.c.NAME"), fieldName: 'nameUrl', type: 'url', typeAttributes: {
                    label: { fieldName: 'Name' },
                    target: '_blank'
                }
            },
            { label: $A.get("$Label.c.TYPE"), fieldName: (namespace + 'CustomType__c'), type: 'text' }
        ];

        if (parent === (namespace + "JobExecution__c")) {
            columns.push({
                label: $A.get("$Label.c.Result"), fieldName: 'resultUrl', type: 'url', typeAttributes: {
                    label: { fieldName: 'resultName' },
                    target: '_blank'
                }
            });
            columns.push({ label: $A.get("$Label.c.STATUS"), fieldName: (namespace + 'Status__c'), type: 'text' });
        } else if (parent === (namespace + "User_Story__c")) {
            columns.push({ label: $A.get("$Label.c.Execution_Sequence"), fieldName: (namespace + 'ExecutionSequence__c'), type: 'picklist' });
        }

        columns.push({
            type: 'action', typeAttributes: {
                rowActions: [
                    { label: $A.get("$Label.c.EDIT"), name: 'edit' },
                    { label: $A.get("$Label.c.DELETE"), name: 'delete' }
                ]
            }
        });

        return columns;
    },

    showErrors: function (errors, label) {
        if (errors && errors[0] && errors[0].message) {
            this.showToast($A.get("$Label.c.ERROR"), "error", label + errors[0].message);
        } else {
            this.showToast($A.get("$Label.c.ERROR"), "error", label + $A.get("$Label.c.Unexpected_Error_Occurred"));
        }
    },

    showToast: function (title, type, message) {
        $A.get("e.force:showToast").fire({ title, type, message });
    }
})