({
    // Can not use init event because the component must be rendered before we can publish to a channel
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.publishRequest(component);
    }
});