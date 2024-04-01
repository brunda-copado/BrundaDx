@IsTest
public with sharing class Function extends DomainBuilder {
    // CONSTRUCTOR

    public Function() {
        super(Function__c.SObjectType);
        name('Function');
        apiName('Function_1');
        script('echo hi');
        type('Custom');
        paramaters('[{ "name" : "param1", "defaultValue" : "val1" }]');
        options('[{}]');
        description('Function Description');
        image('core:v1');
        timeout(100);
        workerSize('S');
        version('1');
    }

    // PUBLIC

    public Function name(String name) {
        return (Function) set(Function__c.Name, name);
    }

    public Function apiName(String apiName) {
        return (Function) set(Function__c.API_Name__c, apiName);
    }

    public Function script(String script) {
        return (Function) set(Function__c.Script__c, script);
    }

    public Function type(String type) {
        return (Function) set(Function__c.Type__c, type);
    }

    public Function paramaters(String paramaters) {
        return (Function) set(Function__c.Parameters__c, paramaters);
    }

    public Function options(String options) {
        return (Function) set(Function__c.Options__c, options);
    }

    public Function callbackType(String callbackType) {
        return (Function) set(Function__c.Callback_Type__c, callbackType);
    }

    public Function apexClass(String apexClass) {
        return (Function) set(Function__c.ApexClass__c, apexClass);
    }

    public Function description(String value) {
        return (Function) set(Function__c.Description__c, value);
    }

    public Function image(String value) {
        return (Function) set(Function__c.Image_Name__c, value);
    }

    public Function timeout(Decimal value) {
        return (Function) set(Function__c.Timeout__c, value);
    }

    public Function workerSize(String value) {
        return (Function) set(Function__c.Worker_Size__c, value);
    }

    public Function flowHandler(String value) {
        return (Function) set(Function__c.FlowHandler__c, value);
    }

    public Function version(String value) {
        return (Function) set(Function__c.Version__c, value);
    }

    public Function resultViewerComponent(String value) {
        return (Function) set(Function__c.Result_Viewer_Component__c, value);
    }

    public Function add(Result result) {
        return (Function) result.setParent(Result__c.Function__c, this);
    }
}