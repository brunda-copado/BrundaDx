@IsTest
private with sharing class CredentialShareRecalcTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .admin()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().personaManagement())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void recalculate() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = createPersona('Developer');
            List<Org__c> credentials = getCredentials();
            Persona.ShareCredentialRequest request = new Persona.ShareCredentialRequest();
            request.credentialIds = new List<String>((new Map<String, Org__c>(credentials)).keySet());
            request.personaId = personaDefinition.Id;
            PersonaCredentialServiceImpl.share(request);

            // Exercise
            Test.startTest();
            String jobId = Database.executeBatch(new CredentialShareRecalc());
            Test.stopTest();

            // Verify
            AsyncApexJob apexJob = [
                SELECT JobType, TotalJobItems, JobItemsProcessed, Status, CompletedDate, CreatedDate, NumberOfErrors
                FROM AsyncApexJob
                WHERE Id = :jobId
            ];
            System.assertEquals(0, apexJob.NumberOfErrors, 'Batch job should not have errors');

            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_Json__c,
                PersonaDefinitionConfig.class
            );
            List<Org__Share> orgShares = [SELECT Id FROM Org__Share WHERE UserOrGroupId = :config.publicGroupId];
            System.assertEquals(credentials.size(), orgShares.size(), 'Credentials should be shared with the public group');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static List<Org__c> getCredentials() {
        return [SELECT Id FROM Org__c];
    }

    private static Persona_Definition__c createPersona(String name) {
        Group personaGroup = new Group(Name = name, Type = 'Regular');
        insert personaGroup;
        PersonaDefinitionConfig config = new PersonaDefinitionConfig();
        config.publicGroupId = personaGroup.Id;
        Persona_Definition__c persona = new Persona_Definition__c(Name = name, Config_Json__c = JSON.serialize(config));
        insert persona;
        return persona;
    }

    private static void createData() {
        new JobTemplate().name('Promotion_Template').mockAutomation('Promotion').add(new JobStep());
        new JobTemplate().name('PromotionDeployment_Template').mockAutomation('PromotionDeployment').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(
                new Project()
                    .add(new UserStory().title('US1').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US2').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US3').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();
    }
}