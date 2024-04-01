@IsTest
public with sharing class SprintSnapshotBatchTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        new User_t().assign(new PermissionSetAssignment_t().copadoUser()).admin().persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    static void testSnapshotBatch() {
        System.runAs(getRunAsUser()) {
            // Execute
            Test.startTest();
            SprintSnapshotBatch batch = new SprintSnapshotBatch();
            Database.executeBatch(batch);
            Test.stopTest();

            // Verify
            List<Burndown_Item__c> snapshots = [
                SELECT Id, Snapshot_Date__c, Sprint__r.name, Planned_Velocity__c, Actual_Velocity__c
                FROM Burndown_Item__c
                WHERE Snapshot_Date__c != NULL
            ];
            system.assert(snapshots.size() > 0, 'Snapshot records are not inserted for sprint velocity fields.');
        }
    }

    @IsTest
    static void withExistingSnapshotRecordsUpdate() {
        System.runAs(getRunAsUser()) {
            // Setup
            createSprintSnapshots();

            // Execute
            Test.startTest();
            SprintSnapshotBatch.run();
            Test.stopTest();

            // Verify
            List<Burndown_Item__c> snapshots = [
                SELECT Id, Snapshot_Date__c, Planned_Velocity__c, Actual_Velocity__c
                FROM Burndown_Item__c
                WHERE Snapshot_Date__c != NULL
            ];
            system.assert(snapshots.size() == 2, 'New Snapshot records are not inserted for no change in sprint velocity fields.');
        }
    }

    @IsTest
    static void withExistingSnapshotRecordsInsert() {
        System.runAs(getRunAsUser()) {
            // Setup
            createSprintSnapshots();
            updateUserStory();

            // Execute
            Test.startTest();
            SprintSnapshotBatch.run(200);
            Test.stopTest();

            // Verify
            List<Burndown_Item__c> snapshots = [
                SELECT Id, Snapshot_Date__c, Planned_Velocity__c, Actual_Velocity__c
                FROM Burndown_Item__c
                WHERE Snapshot_Date__c != NULL
            ];
            system.assert(snapshots.size() > 2, 'Snapshot records are not inserted for updated sprint velocity fields.');
        }
    }

    @IsTest
    static void testSnapshotScheduler() {
        System.runAs(getRunAsUser()) {
            Test.startTest();
            String hour = String.valueOf(Datetime.now().hour());
            Integer minutes = (Datetime.now().minute() + 5) >= 60 ? (Datetime.now().minute() + 5) - 60 : Datetime.now().minute() + 5;
            String min = String.valueOf(minutes);
            String ss = String.valueOf(Datetime.now().second());

            //parse to cron expression
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
            String jobId = SprintSnapshotBatch.schedule('Burndown Item Job Started At', nextFireTime);

            Test.stopTest();

            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId LIMIT 1];
            System.assertEquals(nextFireTime, ct.CronExpression, 'Scheduler Job is not scheduled with NextFireTime.');
            System.assertEquals(0, ct.TimesTriggered, 'Scheduler Job has run');
        }
    }

    // PRIVATE

    private static void createData() {
        new Sprint()
            .name('Sprint 1')
            .startDate(Date.today().addDays(-8))
            .endDate(Date.today().addDays(8))
            .status('In Progress')
            .add(new UserStory().title('US 1').status('Approved').storyPoints(2))
            .add(new UserStory().title('US 2').status('Draft').storyPoints(2))
            .persist();

        new Sprint()
            .name('Sprint 2')
            .startDate(Date.today().addDays(-8))
            .endDate(Date.today().addDays(8))
            .status('In Progress')
            .add(new UserStory().title('US 1').status('Approved').storyPoints(2))
            .add(new UserStory().title('US 2').status('Draft').storyPoints(2))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Sprint__c getSprint(String name) {
        return [SELECT Id FROM Sprint__c WHERE Name = :name];
    }

    private static void createSprintSnapshots() {
        TestUtilities tu = new TestUtilities();
        Sprint__c sprint = getSprint('Sprint 1');
        tu.insertSObjects(
            'Burndown_Item__c',
            1,
            new Map<String, Object>{ 'Sprint__c' => sprint.Id, 'Snapshot_Date__c' => Date.today().addDays(-2), 'Planned_Velocity__c' => 4 }
        );
    }

    private static void updateUserStory() {
        Sprint__c sprint = getSprint('Sprint 1');
        User_Story__c userStory = [SELECT id, Story_Points_Other__c, Status__c FROM User_Story__c WHERE Sprint__c = :sprint.Id LIMIT 1];
        userStory.Status__c = 'Completed';
        userStory.Story_Points_SFDC__c = 2;
        update userStory;
    }
}