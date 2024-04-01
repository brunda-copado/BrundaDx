public with sharing class GenerateScaRulesetAction {

    public with sharing class Result {
        @InvocableVariable(label='Default Ruleset')
        public List<Static_Code_Analysis_Rule__c> defaultRuleset;

        public Result(List<Static_Code_Analysis_Rule__c> defaultRuleset){
            this.defaultRuleset = defaultRuleset;
        }
    }
    public with sharing class Request {
        @InvocableVariable(label='SCA Settting Id')
        public Id scaSettingId;
        public Request(){}

        public Request(Id scaSettingId){
            this.scaSettingId = scaSettingId;
        }
    }

    // PUBLIC

    @InvocableMethod(
        label='Get default rule set'
        description='Generate default sca rules' 
        category='Static Code Analysis'
        callout=true
    )
    public static List<Result> execute(List<Request> requests) { 
        List<Result> results = new List<Result>();

        List<Id> scaSettingIds = getScaSettingIdFrom(requests);
        try {

            HttpResponse response = new HerokuCallout(getUrl(), HttpMethod.GET)
            .default()
            .request()
            .response();
            List<PmdRule> pmdRules = (List<PmdRule>) JSON.deserialize(response.getBody(), List<PmdRule>.class);

            List<Static_Code_Analysis_Rule__c> scaRules = createScaRulesFrom(pmdRules, scaSettingIds);
            results.add(new Result(scaRules));
            return results;
        } catch(Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static List<Id> getScaSettingIdFrom(List<Request> requests){
        List<Id> result = new List<Id>();

        for(Request request :requests){
            if (String.isNotBlank(request.scaSettingId)) {
                result.add(request.scaSettingId);
            }
        }

        return result;
    }

    private static String getUrl(){
        return Settings.server_url + '/json/v1/code/analysis/static/tool/pmd/rules';
    }

    private static List<Static_Code_Analysis_Rule__c> createScaRulesFrom(List<PmdRule> rules, List<Id> scaSettingIds) {
        
        List<Static_Code_Analysis_Rule__c> result = parseToScaRules(rules,scaSettingIds);
        upsertRules(scaSettingIds, result);

        return result;
    }

    private static List<Static_Code_Analysis_Rule__c> parseToScaRules(List<PmdRule> rules, List<Id> scaSettingIds) {
        List<Static_Code_Analysis_Rule__c> result = new List<Static_Code_Analysis_Rule__c>();
        
        for (PmdRule rule : rules) {
            Static_Code_Analysis_Rule__c scaRule = new Static_Code_Analysis_Rule__c();

            scaRule.Static_Code_Analysis_Settings__c = scaSettingIds[0];
            scaRule.Rule_Name__c = rule.name;
            scaRule.Priority__c = rule.priority;
            scaRule.Message__c = rule.message;
            scaRule.Rule_Reference__c = rule.ref;
            result.add(scaRule);
        }

        return result;
    }

    private static void upsertRules(List<Id> scaSettingIds, List<Static_Code_Analysis_Rule__c> scaRules) {
        Utilities.Secure_DML(
            [SELECT Id FROM Static_Code_Analysis_Rule__c WHERE Static_Code_Analysis_Settings__c In :scaSettingIds],
            Utilities.DML_Action.DEL, schema.SObjectType.Static_Code_Analysis_Settings__c
        );

        Utilities.Secure_DML(scaRules, Utilities.DML_Action.INS, schema.SObjectType.Static_Code_Analysis_Rule__c);
    }

    private class PmdRule {
        public String name { get; set; }
        public String ref { get; set; }
        public String priority { get; set; }
        public String message { get; set; }
    }

}