@SuppressWarnings('PMD')
global with sharing class Parameter {
    public Boolean required;
    public String defaultValue;
    public Boolean sensitive = false;

    @AuraEnabled
    global String name;
    @AuraEnabled
    global String value;

    global Parameter() {
    }

    global Parameter(String name, String value) {
        this.name = name;
        this.value = value;
    }

    global Parameter sensitive(Boolean sensitive) {
        this.sensitive = sensitive;
        return this;
    }

    global Parameter required(Boolean required) {
        this.required = required;
        return this;
    }
}