@IsTest
private class GitSnapshotValidatorTest {
    @TestSetup
    static void setupData() {
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
    static void validateDataForRecordPage() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<CopadoAlert> errorMessages = new List<CopadoAlert>();
            Git_Backup__c gitBackup = getSnapshot();

            // Exercise
            Test.startTest();
            String b = '{"Status":"Ok"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
            errorMessages = GitSnapshotValidator.validateDataForRecordPage(gitBackup.Id);
            Test.stopTest();

            // Assertions
            System.assertEquals(null, errorMessages, 'Data is clean');
        }
    }

    @IsTest
    static void repositoryNotAutenticated() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<CopadoAlert> errorMessages = new List<CopadoAlert>();
            Git_Backup__c gitBackup = getSnapshot();

            // Exercise
            Test.startTest();
            String b = '{"Status":"Ok"';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
            errorMessages = GitSnapshotValidator.validateDataForRecordPage(gitBackup.Id);
            Test.stopTest();

            // Assertions
            System.assertEquals(1, errorMessages.size(), 'Message list is not empty');
            CopadoAlert alert = errorMessages[0];
            Git_Repository__c repository = getRepository();
            String expectedMesage = String.format(Label.SnapshotRepositoryNotAuthenticated, new List<String>{ repository.Name });
            System.assertEquals(expectedMesage, alert.message, 'Git repo is not authenticated');
        }
    }

    @IsTest
    static void withoutPermissions() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<CopadoAlert> errorMessages = new List<CopadoAlert>();
            Git_Backup__c gitBackup = getSnapshot();
            delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'Configure_Snapshot'];

            // Exercise
            Test.startTest();
            errorMessages = GitSnapshotValidator.validateDataForRecordPage(gitBackup.Id);
            Test.stopTest();

            // Assertions
            System.assertEquals(1, errorMessages.size(), 'Message list is not empty');
            CopadoAlert alert = errorMessages[0];
            System.assertEquals(Label.ConfigureSnapshotPermIsRequiredOwner, alert.message, 'User without permission set');
        }
    }

    @IsTest
    static void pipelineIsNotActive() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<CopadoAlert> errorMessages = new List<CopadoAlert>();
            Deployment_Flow__c pipeline = getPipeline();
            pipeline.Active__c = false;
            update pipeline;
            Git_Backup__c gitBackup = getSnapshot();

            // Exercise
            Test.startTest();
            errorMessages = GitSnapshotValidator.validateDataForRecordPage(gitBackup.Id);
            Test.stopTest();

            // Assertions
            System.assertEquals(1, errorMessages.size(), 'Message list is not empty');
            CopadoAlert alert = errorMessages[0];
            System.assertEquals(Label.SnapshotPipelineNotActive, alert.message, 'Pipeline is not active ');
        }
    }

    @IsTest
    static void pipelineWihtoutAction() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<CopadoAlert> errorMessages = new List<CopadoAlert>();
            Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository()
                .name('gitSnapshotRepo')
                .uri('https://github.com/myuser/myrepo.git')
                .persist();

            Environment dev = new Environment().name('devNoAction').type('Sandbox').platform('Other').add(new Credential());
            Environment prod = new Environment().name('devNoAction').type('Sandbox').platform('Other').add(new Credential());

            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                .active(true)
                .mainBranch('main')
                .setPlatform('Other')
                .add(new Connection(dev, prod).branch('dev'))
                .persist();

            Org__c credential = getCredential('devNoAction');

            Git_Backup__c gitBackup = (Git_Backup__c) new GitSnapshot()
                .name('Test Backup')
                .gitRepository(gitRepo.Id)
                .credential(credential.Id)
                .pipeline(pipeline.Id)
                .persist();

            // Exercise
            Test.startTest();
            errorMessages = GitSnapshotValidator.validateDataForRecordPage(gitBackup.Id);
            Test.stopTest();

            // Assertions
            System.assertEquals(1, errorMessages.size(), 'Message list is not empty');
            CopadoAlert alert = errorMessages[0];
            System.assertEquals(Label.SnapshotActionNotDefined, alert.message, 'Pipeline without action');
        }
    }

    // HELPERS

    private static User getRunAsUser() {
        return [SELECT Id, IsActive FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id, Active__c, Platform__c FROM Deployment_Flow__c LIMIT 1];
    }

    private static List<Pipeline_Action__c> getPipelineActions() {
        return [SELECT Id FROM Pipeline_Action__c LIMIT 100];
    }

    private static Git_Backup__c getSnapshot() {
        return [SELECT Id, Name FROM Git_Backup__c LIMIT 1];
    }

    private static Git_Repository__c getRepository() {
        return [SELECT Id, Name FROM Git_Repository__c LIMIT 1];
    }

    private static Id getJobTemplate() {
        return [SELECT Id FROM JobTemplate__c LIMIT 1].Id;
    }

    private static Org__c getCredential(String environmentName) {
        return [
            SELECT Id, Name, Environment__c, OAuth_Signature__c, Platform__c, Environment__r.Platform__c, Environment__r.Name
            FROM Org__c
            WHERE Environment__r.Name = :environmentName
            LIMIT 1
        ];
    }

    private static void createData() {
        new JobTemplate().name('Snapshot Template').mockAutomation('TakeSnapshot').add(new JobStep());
        Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository()
            .name('gitSnapshotRepo')
            .uri('https://github.com/myuser/myrepo.git')
            .persist();

        Environment dev = new Environment().name('dev').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev, prod).branch('dev'))
            .persist();

        Org__c credential = getCredential('dev');

        new GitSnapshot().name('Test Backup').gitRepository(gitRepo.Id).credential(credential.Id).pipeline(pipeline.Id).persist();
    }
}