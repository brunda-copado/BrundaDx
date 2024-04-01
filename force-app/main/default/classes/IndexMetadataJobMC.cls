public with sharing class IndexMetadataJobMC implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    private static final String POTENTIAL_CONFLICT = 'Potential Conflict';
    private static final String SALESFORCE = 'Salesforce';

    private Set<Id> storyIds;
    private Set<Id> projectIds;
    private Boolean enableIndexing;

    // PUBLIC

    public IndexMetadataJobMC() {
        this.storyIds = new Set<Id>();
        this.projectIds = new Set<Id>();
        this.enableIndexing = true;
    }

    public IndexMetadataJobMC userStories(Set<Id> storyIds) {
        this.storyIds = storyIds;
        return this;
    }

    public IndexMetadataJobMC projects(Set<Id> projectIds) {
        this.projectIds = projectIds;
        return this;
    }

    public IndexMetadataJobMC startIndexing() {
        this.enableIndexing = true;
        return this;
    }

    public IndexMetadataJobMC stopIndexing() {
        this.enableIndexing = false;
        return this;
    }

    public void execute(SchedulableContext context) {
        if (!batchAlreadyRunning()) {
            Database.executebatch(this);
        } else if (!alreadyScheduled()) {
            System.schedule(IndexMetadataJobMC.class.getName(), getCronExpression(System.now().addMinutes(1)), this);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(findMetadataInContext());
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        List<User_Story_Metadata__c> contextMetadata = (List<User_Story_Metadata__c>) records;

        Set<Id> metadataIdsToUpdate = new Set<Id>();
        if (this.enableIndexing) {
            metadataIdsToUpdate.addAll(getConflictingMetadata(contextMetadata));
        } else {
            metadataIdsToUpdate.addAll(new Map<Id, User_Story_Metadata__c>(contextMetadata).keySet());
        }

        setNewStatus(metadataIdsToUpdate);
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext context) {
    }

    // PRIVATE

    private Boolean batchAlreadyRunning() {
        return [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE
                    JobType IN ('BatchApex', 'BatchApexWorker')
                    AND Status IN ('Processing', 'Preparing', 'Queued')
                    AND ApexClass.Name = :IndexMetadataJobMC.class.getName()
            ] > 0;
    }

    private Boolean alreadyScheduled() {
        return [SELECT COUNT() FROM AsyncApexJob WHERE JobType IN ('ScheduledApex') AND ApexClass.Name = :IndexMetadataJobMC.class.getName()] > 0;
    }

    private String getCronExpression(Datetime nextRun) {
        return nextRun.second() +
            ' ' +
            nextRun.minute() +
            ' ' +
            nextRun.hour() +
            ' ' +
            nextRun.day() +
            ' ' +
            nextRun.month() +
            ' ? ' +
            nextRun.year();
    }

    private String findMetadataInContext() {
        List<String> fields = new List<String>{
            'User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c',
            'User_Story__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c',
            'ModuleDirectory__c',
            'Metadata_API_Name__c',
            'Type__c'
        };

        String whereCondition = !storyIds.isEmpty()
            ? ('User_Story__c IN :storyIds' +
              (this.enableIndexing
                  ? ' AND (User_Story__r.Project__r.Index_Metadata__c = TRUE OR User_Story__r.Release__r.Project__r.Index_Metadata__c = TRUE)'
                  : ''))
            : !projectIds.isEmpty()
                  ? 'User_Story__c IN (SELECT Id FROM User_Story__c WHERE Project__c IN :projectIds OR Release__r.Project__c IN :projectIds)'
                  : 'User_Story__r.Platform__c != NULL AND User_Story__r.Platform__c != :SALESFORCE AND User_Story__r.Stop_Indexing_Metadata__c = FALSE AND (User_Story__r.Project__r.Index_Metadata__c = TRUE OR User_Story__r.Release__r.Project__r.Index_Metadata__c = TRUE)';

        return String.format(
            'SELECT {0} FROM User_Story_Metadata__c WHERE {1} WITH USER_MODE',
            new List<String>{ String.join(fields, ', '), whereCondition }
        );
    }

    private Set<Id> getConflictingMetadata(List<User_Story_Metadata__c> contextMetadata) {
        Set<Id> result = new Set<Id>();

        List<User_Story_Metadata__c> potentialDuplicates = findPotentialDuplicates(contextMetadata);
        for (Integer i = 0; i < contextMetadata.size(); i++) {
            User_Story_Metadata__c metadata1 = contextMetadata[i];
            for (Integer j = i + 1; j < contextMetadata.size(); j++) {
                User_Story_Metadata__c metadata2 = contextMetadata[j];
                if (duplicatedMetadata(metadata1, metadata2)) {
                    result.add(metadata1.Id);
                    result.add(metadata2.Id);
                }
            }
            for (User_Story_Metadata__c potentialDuplicate : potentialDuplicates) {
                if (duplicatedMetadata(metadata1, potentialDuplicate)) {
                    result.add(metadata1.Id);
                    result.add(potentialDuplicate.Id);
                }
            }
        }

        return result;
    }

    private List<User_Story_Metadata__c> findPotentialDuplicates(List<User_Story_Metadata__c> metadata) {
        Set<Id> metadataIds = new Set<Id>();
        Set<Id> repositories = new Set<Id>();
        Set<String> modules = new Set<String>();
        Set<String> apiNames = new Set<String>();
        Set<String> types = new Set<String>();
        for (User_Story_Metadata__c record : metadata) {
            metadataIds.add(record.Id);
            Id projectRepository = record.User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c;
            if (String.isNotBlank(projectRepository)) {
                repositories.add(projectRepository);
            }
            Id releaseRepository = record.User_Story__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
            if (String.isNotBlank(releaseRepository)) {
                repositories.add(releaseRepository);
            }
            modules.add(record.ModuleDirectory__c);
            apiNames.add(record.Metadata_API_Name__c);
            types.add(record.Type__c);
        }

        return [
            SELECT
                Id,
                User_Story__c,
                ModuleDirectory__c,
                Metadata_API_Name__c,
                Type__c,
                User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                User_Story__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
            FROM User_Story_Metadata__c
            WHERE
                Id NOT IN :metadataIds
                AND Type__c IN :types
                AND ModuleDirectory__c IN :modules
                AND Metadata_API_Name__c IN :apiNames
                AND (User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c IN :repositories
                OR User_Story__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c IN :repositories)
                AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
                AND (User_Story__r.Project__r.Index_Metadata__c = TRUE
                OR User_Story__r.Release__r.Project__r.Index_Metadata__c = TRUE)
            WITH USER_MODE
        ];
    }

    private Boolean duplicatedMetadata(User_Story_Metadata__c metadata1, User_Story_Metadata__c metadata2) {
        return (metadata1.User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c ==
            metadata2.User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c ||
            metadata1.User_Story__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c ==
            metadata2.User_Story__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c) &&
            metadata1.ModuleDirectory__c == metadata2.ModuleDirectory__c &&
            metadata1.Metadata_API_Name__c == metadata2.Metadata_API_Name__c &&
            metadata1.Type__c == metadata2.Type__c;
    }

    private void setNewStatus(Set<Id> metadataIdsToUpdate) {
        List<User_Story_Metadata__c> metadataToUpdate = new List<User_Story_Metadata__c>();
        for (Id metadataId : metadataIdsToUpdate) {
            metadataToUpdate.add(new User_Story_Metadata__c(Id = metadataId, Status__c = this.enableIndexing ? POTENTIAL_CONFLICT : ''));
        }
        DML.safeUpdate(
            metadataToUpdate,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User_Story_Metadata__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'IndexMetadataJobMC.setNewStatus'
                }
            )
        );
    }
}