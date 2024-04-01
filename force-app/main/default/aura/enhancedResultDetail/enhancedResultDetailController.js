({
    show: function (cmp, evt, hlp) {
        cmp.set('v.showResultModal', true);
        cmp.set('v.recordId', evt.getParam('arguments').recordId);
        cmp.set('v.isConsolidatedResult', evt.getParam('arguments').isConsolidated);
        return hlp.init(cmp);
    },

    handleRecordIdChange: function (cmp, evt, hlp) {
        hlp.handleRecordIdChange(cmp, evt);
    },

    handleClose: function (cmp, evt, hlp) {
        hlp.close(cmp);
    },

    handleSort: function (cmp, evt, hlp) {
        hlp.handleSort(cmp);
    },

    handleRefresh: function (cmp, evt, hlp) {
        hlp.getResultDetails(cmp);
    },

    setHasContentForResultViewer: function (cmp, evt, hlp) {
        hlp.resultViewerHasContent = true;
        hlp.showContent(cmp);
    },

    setHasContentForDynamicUISectionContainer: function (cmp, evt, hlp) {
        hlp.dynamicUISectionHasContent = true;
        hlp.showContent(cmp);
    }
});