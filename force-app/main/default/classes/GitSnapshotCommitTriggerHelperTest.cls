@isTest(seeAllData=false)
public with sharing class GitSnapshotCommitTriggerHelperTest {
    @TestSetup
    static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    private static void createData() {
        Environment__c otherEnvironment = (Environment__c) new Environment().name('dev1').type('Sandbox').platform('Other').persist();
        new Credential().name('otherCredential').oAuthSignature('authentication').environment(otherEnvironment.Id).persist();
    }

    @isTest
    static void testSnapshotCommitInsertByPass() {
        test.startTest();
        Git_Org_Commit__c snapshotCommit = (Git_Org_Commit__c) new SnapshotCommit().credentialId(getCredential('Other')?.Id).persist();
        System.assertEquals(snapshotCommit.Id != null, true, 'Snapshot Commit got inserted');
        test.stopTest();
    }

    private static Org__c getCredential(String platform) {
        return [
            SELECT Id, Name, Environment__c, OAuth_Signature__c, Platform__c, Environment__r.Platform__c, Environment__r.Name
            FROM Org__c
            WHERE Platform__c = :platform
            LIMIT 1
        ];
    }
}