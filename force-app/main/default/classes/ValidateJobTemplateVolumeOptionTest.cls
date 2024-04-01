@IsTest
private class ValidateJobTemplateVolumeOptionTest {
    @IsTest
    private static void executeWithoutVolumeOptions() {
        // Setup
        Exception expectedException = null;

        JobTemplate__c template = new JobTemplate__c();
        template.Name = 'Sample';
        template.Version__c = 1;
        template.VolumeOptions__c = '[ { "name": "volumeEnabled", "value": "true" } ]';

        // Exercise
        try {
            insert template;
        }
        catch(Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.MissingVolumeOptions));
    }

     @IsTest
    private static void executeWithMaxVolumeSizeOptions() {
        // Setup
        Exception expectedException = null;

        JobTemplate__c template = new JobTemplate__c();
        template.Name = 'Sample';
        template.Version__c = 1;
        template.VolumeOptions__c = '[ { "name": "volumeSize", "value": "'+ Settings.maximumVolumeSize + 1 + '" }, { "name": "volumeTTL", "value": "1440" }, { "name": "volumeEnabled", "value": "true" } ]';

        // Exercise
        try {
            insert template;
        }
        catch(Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
    }

    @IsTest
    private static void executeWithMaxVolumeTTLOptions() {
        // Setup
        Exception expectedException = null;

        JobTemplate__c template = new JobTemplate__c();
        template.Name = 'Sample';
        template.Version__c = 1;
        template.VolumeOptions__c = '[ { "name": "volumeSize", "value": "1" }, { "name": "volumeTTL", "value": "' + (Settings.MAX_VOLUME_TTL + 1) + '" }, { "name": "volumeEnabled", "value": "true" } ]';

        // Exercise
        try {
            insert template;
        }
        catch(Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
    }

     @IsTest
    private static void executeWithMinVolumeTTLOptions() {
        // Setup
        Exception expectedException = null;

        JobTemplate__c template = new JobTemplate__c();
        template.Name = 'Sample';
        template.Version__c = 1;
        template.VolumeOptions__c = '[ { "name": "volumeSize", "value": "1" }, { "name": "volumeTTL", "value": "' + (Settings.MIN_VOLUME_TTL - 1) + '" }, { "name": "volumeEnabled", "value": "true" } ]';

        // Exercise
        try {
            insert template;
        }
        catch(Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
    }
}