@isTest
public with sharing class GitRepository extends DomainBuilder {
    public GitRepository() {
        super(Git_Repository__c.SObjectType);
    }

    public GitRepository name(String name) {
        return (GitRepository) set(Git_Repository__c.Name, name);
    }

    public GitRepository gitProvider(String gitProvider) {
        return (GitRepository) set(Git_Repository__c.Git_Provider__c, gitProvider);
    }

    public GitRepository allowFunctionsGitCache(String allowFunctionsGitCache) {
        return (GitRepository) set(Git_Repository__c.Allow_Functions_Git_Cache__c, allowFunctionsGitCache);
    }

    public GitRepository branchBaseURL(String branchBaseURL) {
        return (GitRepository) set(Git_Repository__c.Branch_Base_URL__c, branchBaseURL);
    }

    public GitRepository commitBaseURL(String commitBaseURL) {
        return (GitRepository) set(Git_Repository__c.Commit_Base_URL__c, commitBaseURL);
    }

    public GitRepository pullRequestBaseURL(String pullRequestBaseURL) {
        return (GitRepository) set(Git_Repository__c.Pull_Request_Base_URL__c, pullRequestBaseURL);
    }

    public GitRepository sourceFormat(String sourceFormat) {
        return (GitRepository) set(Git_Repository__c.Source_Format__c, sourceFormat);
    }

    public GitRepository tagBaseURL(String tagBaseURL) {
        return (GitRepository) set(Git_Repository__c.Tag_Base_URL__c, tagBaseURL);
    }

    public GitRepository uri(String uri) {
        return (GitRepository) set(Git_Repository__c.URI__c, uri);
    }
}