@IsTest
private with sharing class GitRepositoryControllerTest {
    private static final String SSH_KEY_NAME = 'id_rsa.pub';
    private static final String EXTRA_HEADERS = 'Extra Headers';

    @TestSetup
    private static void setup() {
        insertData();
    }

    @IsTest
    private static void initSSHRepository() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');
        
        Attachment sshKey = new Attachment(Name = SSH_KEY_NAME, ParentId = repository.Id, Body = Blob.valueOf('aszxdcRwfdftg123'));
        insert sshKey;
        
        insert new Sensitive_Information__c(Name = repository.Id);

        // Exercise
        Test.startTest();
        String result = GitRepositoryController.init(repository.Id);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            '{"username":null,"sshKey":{"key":"aszxdcRwfdftg123","attachmentId":"' + sshKey.Id + '"},"headers":null,"authType":"SSH"}', 
            result, 
            'Incorrect configuration returned for repository with SSH connection.'
        );
    }

    @IsTest
    private static void initHTTPSRepository() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');
        update new Git_Repository__c(Id = repository.Id, URI__c = 'https://github.com/rsluzhenko/copado-vlocity-cmt.git');
        
        Note headers = new Note(Title = EXTRA_HEADERS, ParentId = repository.Id, Body = 'Accept: application/json');
        insert headers;
        
        insert new Sensitive_Information__c(Name = repository.Id, Username__c = 'rtoro+gitrepository@copado.com');

        // Exercise
        Test.startTest();
        String result = GitRepositoryController.init(repository.Id);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            '{"username":"rtoro+gitrepository@copado.com","sshKey":null,"headers":"Accept: application/json","authType":"HTTPS"}', 
            result, 
            'Incorrect configuration returned for repository with HTTPS connection.'
        );
    }

    @IsTest
    private static void saveWithShortExtraHeaders() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');

       insert new Note(
           Title = EXTRA_HEADERS, 
           ParentId = repository.Id, 
           Body = 'Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json'
        );

        // Exercise
        Test.startTest();
        GitRepositoryController.save(repository.Id, 'HTTPS', 'rtoro+gitrepository@copado.com', 'azs123!!??@', 'Accept: application/json');
        Test.stopTest();

        // Verify
        Sensitive_Information__c result = Sensitive_Information__c.getInstance(repository.Id);
        List<Note> headers = [SELECT Id FROM Note WHERE ParentId = :repository.Id AND Title = :EXTRA_HEADERS LIMIT 1];
        
        Assert.areEqual(result.Name, repository.Id, 'Incorrect sensitive information name: should be the git repository record id.');
        Assert.areEqual(result.Username__c, 'rtoro+gitrepository@copado.com', 'Incorrect username stored in sensitive information: should be gitrepouser@copado.com.');
        Assert.areEqual('azs123!!??@', DeployAPI.decryptAPIKey(result.Password__c), 'Incorrect encrypted password stored in sensitive information: should be azs123!!??@.');
        Assert.areEqual('Accept: application/json', DeployAPI.decryptAPIKey(result.Extra_Header__c), 'Incorrect extra headers stored in sensitive information: should be Accept: application/json.');
        Assert.isTrue(headers.isEmpty(), 'Short extra headers must be stored in a Sensitive Information record and old Note records must be deleted.');
    }

    @IsTest
    private static void saveWithLongExtraHeaders() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');

        // Exercise
        Test.startTest();
        GitRepositoryController.save(
            repository.Id, 
            'HTTPS', 
            'rtoro+gitrepository@copado.com', 
            'azs123!!??@', 
            'Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json'
        );
        Test.stopTest();

        // Verify
        Sensitive_Information__c result = Sensitive_Information__c.getInstance(repository.Id);
        List<Note> headers = [SELECT Body FROM Note WHERE ParentId = :repository.Id AND Title = :EXTRA_HEADERS LIMIT 1];
        
        Assert.areEqual(result.Name, repository.Id, 'Incorrect sensitive information name: should be the git repository record id.');
        Assert.areEqual(result.Username__c, 'rtoro+gitrepository@copado.com', 'Incorrect username stored in sensitive information: should be gitrepouser@copado.com.');
        Assert.areEqual('azs123!!??@', DeployAPI.decryptAPIKey(result.Password__c), 'Incorrect encrypted password stored in sensitive information: should be azs123!!??@.');
        Assert.isTrue(String.isBlank(result.Extra_Header__c), 'Long extra headers must be stored in a Note record.');
        Assert.isTrue(!headers.isEmpty(), 'Long extra headers must be stored in a Note record.');
        Assert.areEqual(
            'Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json,Accept: application/json', 
            DeployAPI.decryptAPIKey(headers[0].Body), 
            'Incorrect extra header value stored in Note record.'
        );
    }

    @IsTest
    private static void validateGitConnection() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"Status":"Ok"}', null));

        // Exercise
        Test.startTest();
        String result = GitRepositoryController.validateGitConnection(repository.Id);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            '{"success":true,"message":"Credentials validated. "}', 
            result, 
            'Incorrect git connection validation result: validation status should be OK.'
        );
    }

    @IsTest
    private static void createSSHKey() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{"ok": "Keys created"}', null));

        // Exercise
        Test.startTest();
        String result = GitRepositoryController.createSSHKey(repository.Id);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            '{"ok": "Keys created"}', 
            result, 
            'Incorrect SSH key generation result: response should be OK.'
        );
    }

    @IsTest
    private static void getSSHKey() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');

        Attachment sshKey = new Attachment(Name = SSH_KEY_NAME, ParentId = repository.Id, Body = Blob.valueOf('aszxdcRwfdftg123'));
        insert sshKey;

        // Exercise
        Test.startTest();
        String result = GitRepositoryController.getSSHKey(repository.Id);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            '{"key":"aszxdcRwfdftg123","attachmentId":"' + sshKey.Id + '"}', 
            result, 
            'Incorrect SSH key value returned for selected repository.'
        );
    }

    @IsTest
    private static void deleteSSHKey() {
        // Setup
        Git_Repository__c repository = repository('copado-vlocity-cmt');

        Attachment sshKey = new Attachment(Name = SSH_KEY_NAME, ParentId = repository.Id, Body = Blob.valueOf('aszxdcRwfdftg123'));
        insert sshKey;

        // Exercise
        Test.startTest();
        GitRepositoryController.deleteSSHKey(sshKey.Id);
        Test.stopTest();

        // Verify
        List<Attachment> result = [SELECT Id FROM Attachment WHERE Id = :sshKey.Id];

        Assert.isTrue(result.isEmpty(), 'SSH Key for selected repository must have been deleted.');
    }

    // HELPER

    private static Git_Repository__c repository(String name) {
        return [SELECT Name FROM Git_Repository__c WHERE Name = :name LIMIT 1];
    }

    private static void insertData() {
        User user = user('gitrepouser@copado.com');
        insert user;

        System.runAs(user) {
            TestUtilities.setTestSettingsEE();
        }

        new GitRepository()
                .name('copado-vlocity-cmt')
                .gitProvider('Bitbucket')
                .sourceFormat('Metadata')
                .uri('git@github.com:rsluzhenko/copado-vlocity-cmt.git')
                .persist();
    }

    private static User user(String username) {
        return new User(
            Username = userName,
            Email = userName,
            firstName = 'testx',
            lastName = 'userx',
            Alias = 'useruser',
            emailencodingkey = 'UTF-8',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id
        );
    }
}