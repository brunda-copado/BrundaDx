@isTest
public with sharing class GitSnapshot extends DomainBuilder {
    public GitSnapshot() {
        super(Git_Backup__c.SObjectType);
    }

    public GitSnapshot name(String name) {
        return (GitSnapshot) set(Git_Backup__c.Name, name);
    }

    public GitSnapshot branch(String branch) {
        return (GitSnapshot) set(Git_Backup__c.Branch__c, branch);
    }

    public GitSnapshot complianceStatus(String complianceStatus) {
        return (GitSnapshot) set(Git_Backup__c.Compliance_Status__c, complianceStatus);
    }

    public GitSnapshot credential(String credential) {
        return (GitSnapshot) set(Git_Backup__c.Org__c, credential);
    }

    public GitSnapshot cronExpression(String cronExpression) {
        return (GitSnapshot) set(Git_Backup__c.Cron_Expression__c, cronExpression);
    }

    public GitSnapshot extenalId(String extenalId) {
        return (GitSnapshot) set(Git_Backup__c.External_Id__c, extenalId);
    }

    public GitSnapshot frequency(String frequency) {
        return (GitSnapshot) set(Git_Backup__c.Frequency__c, frequency);
    }

    public GitSnapshot mcFrequency(String mcFrequency) {
        return (GitSnapshot) set(Git_Backup__c.Snapshot_Frequency__c, mcFrequency);
    }

    public GitSnapshot gitRepository(String gitRepository) {
        return (GitSnapshot) set(Git_Backup__c.Git_Repository__c, gitRepository);
    }

    public GitSnapshot gitSnapshotPermissions(String gitSnapshotPermissions) {
        return (GitSnapshot) set(Git_Backup__c.Git_Snapshot_Permissions__c, gitSnapshotPermissions);
    }

    public GitSnapshot lastComplianceScanDate(String lastComplianceScanDate) {
        return (GitSnapshot) set(Git_Backup__c.Last_Compliance_Scan_Date__c, lastComplianceScanDate);
    }

    public GitSnapshot lastSnapshot(String lastSnapshot) {
        return (GitSnapshot) set(Git_Backup__c.Last_Backup__c, lastSnapshot);
    }

    public GitSnapshot metadataTypes(String metadataTypes) {
        return (GitSnapshot) set(Git_Backup__c.Metadata_Types__c, metadataTypes);
    }

    public GitSnapshot otherInformation(String otherInformation) {
        return (GitSnapshot) set(Git_Backup__c.Other_Information__c, otherInformation);
    }

    public GitSnapshot pipeline(String pipeline) {
        return (GitSnapshot) set(Git_Backup__c.Pipeline__c, pipeline);
    }

    public GitSnapshot scope(String scope) {
        return (GitSnapshot) set(Git_Backup__c.Scope__c, scope);
    }
}