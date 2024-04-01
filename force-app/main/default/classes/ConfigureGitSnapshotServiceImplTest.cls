@IsTest
private class ConfigureGitSnapshotServiceImplTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().configureSnapshots())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    static void insertNewRecordWithExternalIdEmpty() {
        System.runAs(getRunAsUser()) {
            // Setup
            Actions.ConfigureGitSnapshotRequest request = new Actions.ConfigureGitSnapshotRequest();
            request.branch = 'dev';
            request.credentialId = getCredential().Id;
            request.repositoryId = getRepository().Id;
            request.additionalInformation = '';
            request.scope = '';
            request.pipelineId = getPipeline().Id;
            request.externalId = '';

            // Exercise
            Test.startTest();
            Actions.GitSnapshotService.configure(request);
            Test.stopTest();

            // Assertions
            Git_Backup__c snapshot = getExistingSnapshotDetails();
            System.assertNotEquals(null, snapshot.Id, 'Snapshot record is inserted');
            System.assertEquals(snapshot.Id, snapshot.External_Id__c, 'External Id populated with snapshot id');
        }
    }

    @IsTest
    static void insertNewRecordWithExternalIdFilled() {
        System.runAs(getRunAsUser()) {
            // Setup
            Actions.ConfigureGitSnapshotRequest request = new Actions.ConfigureGitSnapshotRequest();
            request.branch = 'dev';
            request.credentialId = getCredential().Id;
            request.repositoryId = getRepository().Id;
            request.additionalInformation = '';
            request.scope = '';
            request.pipelineId = getPipeline().Id;
            request.externalId = 'test_snapshot';

            // Exercise
            Test.startTest();
            Actions.GitSnapshotService.configure(request);
            Test.stopTest();

            // Assertions
            Git_Backup__c snapshot = getExistingSnapshotDetails();
            System.assertNotEquals(null, snapshot.Id, 'Snapshot record is inserted');
            System.assertNotEquals(snapshot.Id, snapshot.External_Id__c, 'External Id not populated with snapshot id');
        }
    }

    // HELPERS

    private static void createData() {
        Credential source = new Credential().oAuthSignature('authentication');

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().platform('Other').add(new Credential().oAuthSignature('authentication'))
                    )
                    .branch('dev1')
            )
            .add(
                new Connection(
                        new Environment().platform('Other').add(new Credential().oAuthSignature('authentication')),
                        new Environment().platform('Other').add(new Credential().oAuthSignature('authentication'))
                    )
                    .branch('dev2')
            )
            .add(new Project().add(new UserStory().credential(source)))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Org__c getCredential() {
        return [SELECT Id, OAuth_Signature__c, Platform__c FROM Org__c WHERE OAuth_Signature__c != NULL LIMIT 1];
    }

    private static Git_Repository__c getRepository() {
        return [SELECT Id FROM Git_Repository__c LIMIT 1];
    }

    private static Git_Backup__c getExistingSnapshotDetails() {
        List<Git_Backup__c> result = [
            SELECT
                Id,
                Branch__c,
                Org__c,
                Git_Repository__c,
                Other_Information__c,
                Scope__c,
                Pipeline__c,
                External_Id__c,
                Cron_Expression__c,
                Snapshot_Frequency__c
            FROM Git_Backup__c
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return !result.isEmpty() ? result[0] : new Git_Backup__c();
    }
}