@IsTest
private class SetJobTemplateApiNameTest {
    @IsTest
    private static void execute() {
        // Setup
        JobTemplate__c template = new JobTemplate__c();
        template.Name = 'Sample';
        template.Version__c = 1;

        // Exercise
        insert template;

        // Verify
        System.assertEquals('Sample_1', [SELECT ApiName__c FROM JobTemplate__c WHERE Id = :template.Id].ApiName__c, 'The template API Name matches');
    }

    @IsTest
    private static void executeWithNoName() {
        // Setup
        JobTemplate__c template = new JobTemplate__c();
        template.Version__c = 1;

        // Exercise
        insert template;

        // Verify
        System.assertEquals('null_1', [SELECT ApiName__c FROM JobTemplate__c WHERE Id = :template.Id].ApiName__c, 'The template API Name matches');
    }

    @IsTest
    private static void executeStepNameWithCharacters() {
        // Setup
        JobTemplate__c template = new JobTemplate__c();
        template.Name = 'Hello! Template name..';
        template.Version__c = 1;

        // Exercise
        insert template;

        // Verify
        System.assertEquals(
            'Hello_Template_name__1',
            [SELECT ApiName__c FROM JobTemplate__c WHERE Id = :template.Id]
            .ApiName__c,
            'The API name matches.'
        );
    }
}