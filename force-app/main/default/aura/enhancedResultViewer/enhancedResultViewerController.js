({
    showDetail: function (cmp, evt, hlp) {
        const resultId = evt.getParam('resultId');
        const isConsolidated = evt.getParam('isConsolidated');
        cmp.set("v.isVisible", true);

        cmp.find("enhancedResultDetail")
            .show(resultId, isConsolidated)
            .then($A.getCallback(jobStepName => {
                cmp.set('v.modalTitle', `${$A.get('$Label.c.Result')} - ${jobStepName}`);
            }));
    },


    handleClose: function (cmp, evt, hlp) {
        cmp.find("enhancedResultDetail").close();
        cmp.set("v.isVisible", false);
    }
});