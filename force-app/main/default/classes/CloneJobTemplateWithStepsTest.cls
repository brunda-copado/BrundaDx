@IsTest
private class CloneJobTemplateWithStepsTest {
    
    @TestSetup
    private static void makeData() {
        setupUser();
    }


    @IsTest
    private static void cloneWithNoSteps() {
        System.runAs(runAsUser()) {

            // Setup

            JobTemplate__c job = (JobTemplate__c) new JobTemplate()
                .name('Job1')
                .volumeOptions('[{}]')
                .persist();

            JobTemplate__c toBeCloned = job.clone();
            toBeCloned.Name = 'Job2';
            toBeCloned.Version__c = 2;

            // Exercise

            Id clonedJobId = CloneJobTemplateWithSteps.cloneTemplate(job.Id, toBeCloned);

            // Verify

            JobTemplate__c clonedJob = jobTemplate('Job2');

            System.assertEquals(clonedJobId, clonedJob.Id, 'Incorrect Job Template.');
            System.assertEquals(2, clonedJob.Version__c, 'Incorrect Version.');
            System.assertEquals('Custom', clonedJob.Type__c, 'Incorrect Type.');
            System.assertEquals(
                job.VolumeOptions__c,
                clonedJob.VolumeOptions__c,
                'Incorrect Volume Options.'
            );

            System.assertEquals(0, clonedJob.JobSteps__r.size(), 'Steps cloned incorrectly.');
        }
    }


    @IsTest
    private static void cloneWithSteps() {
        System.runAs(runAsUser()) {

            // Setup

            JobTemplate__c job = (JobTemplate__c) new JobTemplate()
                .name('Job1')
                .volumeOptions('[{}]')
                .add(new JobStep().name('S1'))
                .add(new JobStep().name('S2'))
                .persist();

            JobTemplate__c newJob = job.clone();
            newJob.Name = 'Job2';
            newJob.Version__c = 2;
            newJob.Description__c = 'Sample';

            // Exercise

            Id clonedJobId = CloneJobTemplateWithSteps.cloneTemplate(job.Id, newJob);

            // Verify

            JobTemplate__c clonedJob = jobTemplate('Job2');

            System.assertEquals(clonedJobId, clonedJob.Id, 'Incorrect Job Template.');
            System.assertEquals(2, clonedJob.Version__c, 'Incorrect Version.');
            System.assertEquals('Custom', clonedJob.Type__c, 'Incorrect Type.');
            System.assertEquals('Sample', clonedJob.Description__c, 'Incorrect Description.');
            System.assertEquals(
                job.VolumeOptions__c,
                clonedJob.VolumeOptions__c,
                'Incorrect Volume Options.'
            );

            System.assertEquals(2, clonedJob.JobSteps__r.size(), 'Steps cloned incorrectly.');
            System.assertEquals(
                'Job2_2_S1_0',
                clonedJob.JobSteps__r[0].ApiName__c,
                'Steps cloned incorrectly.'
            );
        }
    }


    @IsTest
    private static void exception() {
        System.runAs(runAsUser()) {

            // Setup

            Exception expectedEx = null;

            JobTemplate__c job = (JobTemplate__c) new JobTemplate().name('Job1').persist();

            // Exercise

            try {
                CloneJobTemplateWithSteps.cloneTemplate(job.Id, job);
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
        }
    }

    // HELPER

    private static void setupUser() {
        TestUtilities.getAllMultilicense();

        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }


    private static User runAsUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }


    private static JobTemplate__c jobTemplate(String name) {
        return [
            SELECT
                Version__c,
                Type__c,
                VolumeOptions__c,
                Description__c,
                (SELECT ApiName__c FROM JobSteps__r ORDER BY Name)
            FROM JobTemplate__c
            WHERE Name = :name
        ];
    }
}