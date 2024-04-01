@IsTest
public class Package_t extends DomainBuilder {
    public Package_t() {
        super(Artifact__c.SObjectType);
    }

    public Package_t name(String name) {
        return (Package_t) set(Artifact__c.Name, name);
    }

    public Package_t pipelineId(Id pipelineId) {
        return (Package_t) set(Artifact__c.Pipeline__c, pipelineId);
    }

    public Package_t repositoryId(Id repositoryId) {
        return (Package_t) set(Artifact__c.Artifact_Repository__c, repositoryId);
    }

    public Package_t packageType(String packageType) {
        return (Package_t) set(Artifact__c.Package_Type__c, packageType);
    }

    public Package_t recordTypeId(Id recordTypeId) {
        return (Package_t) set(Artifact__c.RecordTypeId, recordTypeId);
    }

    public Package_t packageArtifactRecordType() {
        return recordTypeId(SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId());
    }

    public Package_t add(PackageVersion version) {
        return (Package_t) version.setParent(Artifact_Version__c.Artifact__c, this);
    }
}