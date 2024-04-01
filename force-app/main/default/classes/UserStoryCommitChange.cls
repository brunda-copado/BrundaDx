public with sharing class UserStoryCommitChange {
    @AuraEnabled
    public String a { get; set; } // "action" add, delete, ret-only, full pps, ...
    @AuraEnabled
    public String c { get; set; } // "category": copadodx, vlocity, cpq, ...
    @AuraEnabled
    public String m { get; set; } // "module directory" e.g. force-app/main/default
    @AuraEnabled
    public String n { get; set; } // "name"
    @AuraEnabled
    public String t { get; set; } // "type"
    @AuraEnabled
    public String j { get; set; } // "json additional information"

    public CommitAction.Change parse() {
        CommitAction.Change result = new CommitAction.Change();
        result.a = a;
        result.c = c;
        result.m = m;
        result.n = n;
        result.t = t;
        result.j = j;
        return result;
    }
}