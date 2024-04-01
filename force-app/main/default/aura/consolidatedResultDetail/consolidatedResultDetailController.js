({
    doInit: function (cmp, evt, hlp) {
        const getSubJobResultId = cmp.get("c.getSubJobResultId");

        getSubJobResultId.setParams({
            resultId: cmp.get("v.recordId")
        });


        getSubJobResultId.setCallback(this, (response) => {
            const state = response.getState();

            if (state === "SUCCESS" && response.getReturnValue()) {
                cmp.find("enhancedResultDetail").show(response.getReturnValue(), true);
                cmp.set("v.isVisible", true);
            } else if (state === "ERROR") {
                const errors = response.getError();
                let errorMessage;
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = $A.get("$Label.c.RECORD_NOT_FOUND") + ' ' + errors[0].message;
                } else {
                    errorMessage = $A.get("$Label.c.RECORD_NOT_FOUND");
                }
                cmp.set('v.errorMessage', errorMessage);
            }
        });

        $A.enqueueAction(getSubJobResultId);
    },

    toggleSection: function (cmp, evt, hlp) {
        const sectionAuraId = evt.currentTarget.dataset.auraId;
        const sectionDiv = cmp.find(sectionAuraId).getElement();
        const sectionState = sectionDiv.getAttribute('class').search('slds-is-open');
        const className = 'slds-section' + (sectionState == -1 ? ' slds-is-open' : ' slds-is-close');
        sectionDiv.setAttribute('class', className);
    }
})