({
    init: function (cmp, evt, hlp) {
        hlp.setValidationSetting(cmp);
    },
    close: function (cmp, evt, hlp) {
        hlp.closeModal();
    },
    validate: function (cmp, evt, hlp) {
        hlp.validate(cmp);
    }
});