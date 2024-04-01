@IsTest
public class PackageVersion extends DomainBuilder {
    public PackageVersion() {
        super(Artifact_Version__c.SObjectType);
    }
    
    public PackageVersion packageId(Id packageId) {
        return (PackageVersion) set(Artifact_Version__c.Artifact__c, packageId);
    }

    public PackageVersion versionName(String name) {
        return (PackageVersion) set(Artifact_Version__c.Version_Name__c, name);
    }

    public PackageVersion versionNumber(String versionNumber) {
        return (PackageVersion) set(Artifact_Version__c.Version_number__c, versionNumber);
    }
}