({
    init: function (component) {
        component.set('v.loading', true);
        
        const recordId = component.get('v.recordId');
        const fieldApiName = component.get('v.jobExecutionField');
        
        if (!(recordId && fieldApiName)) {
            this.showErrors(component, null, $A.get('$Label.c.Incorrect_Parameter'));
            return;
        }

        const getJobIds = component.get('c.getJobIds');
        getJobIds.setParams({
            recordId,
            fieldApiName,
        });

        getJobIds.setCallback(this, (response) => {
            if (response.getState() === 'SUCCESS') {
                const jobIds = response.getReturnValue();
                component.set('v.jobExecutionIds', jobIds);
                component.set('v.hasJobs', Boolean(jobIds.length));
            } else {
                this.showErrors(component, response.getError());
            }
            component.set('v.loading', false);
        });

        $A.enqueueAction(getJobIds);
    },

    showErrors: function (component, errors) {
        let errorMessage;
        if (errors && errors[0] && errors[0].message) {
            errorMessage = errors[0].message;
        } else {
            errorMessage = $A.get('$Label.c.Unexpected_Error_Occurred');
        }
        component.set('v.errorMessage', errorMessage);
    }
})