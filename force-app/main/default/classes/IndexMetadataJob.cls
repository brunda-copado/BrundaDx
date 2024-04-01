/**
 * This batch is called in this scenarios:
 * 1) When Index Metadata Field is set to true in Project
 * 2) When Attachment on User Story is created, Updated ('MetaData','Delete MetaData', 'Git MetaData')
 * 3) When enable or disable Stop_Indexing_Metadata__c on User Story
 *
 * The batch is executed twice, with the following behaviors respectively:
 * 1) The batch will create User_Story_Metadata__c record per key Type.ApiName of whatever was committed in the User Story
 * 2) The batch will look for all the possible duplicates across all the User_Story_Metadata__c records and mark them as potentially conflicted
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
global with sharing class IndexMetadataJob implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    // Constants
    private static final String DELETEMETADATA = 'Delete MetaData';
    private static final Integer ONE_MINUTE = 1;

    public Set<Id> storyIds;
    //Flag to specify which behavior will this batch run.
    public Boolean checkPotentialConflict;
    public Boolean zeroizePotentialConflicts;

    global Database.QueryLocator start(Database.BatchableContext bContext) {
        UserStoriesMetadataSelector metadata = new UserStoriesMetadataSelector();
        UserStoriesSelector stories = new UserStoriesSelector();
        if (enableStopIdxMetadata()) {
            return metadata.byStoryStatus(storyIds, 'Potential Conflict');
        } else if (disableStopIdxMetadata()) {
            return metadata.byMetadataIndexingEnabled(namesByApiName(apiNames(storyIds)));
        } else if (isAttachmentBased()) {
            return stories.byIdWithIndexingEnabled(storyIds);
        } else if (isProjectBased()) {
            return stories.withIndexingEnabled();
        } else {
            return metadata.byMetadatanameStatusIndexingEnabled(namesByEmptyStatus(), '', storyIds);
        }
    }

    global void execute(SchedulableContext sContext) {
        // Check if IndexMetadataJob is already running
        List<ApexClass> apList = [SELECT Id FROM ApexClass WHERE Name = 'IndexMetadataJob'];
        Integer enqueuedJobs = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex' AND Status IN ('Processing', 'Preparing', 'Queued') AND ApexClassID = :apList[0].Id
        ];
        if (enqueuedJobs <= 0) {
            IndexMetadataJob b = new IndexMetadataJob();
            Database.executebatch(b, 50);
        } else {
            Datetime sysTime = System.now().addMinutes(ONE_MINUTE);
            IndexMetadataJob imJob = new IndexMetadataJob();
            imJob.zeroizePotentialConflicts = this.zeroizePotentialConflicts;
            imJob.checkPotentialConflict = this.checkPotentialConflict;
            imJob.storyIds = this.storyIds;
            String cronExpression =
                '' +
                sysTime.second() +
                ' ' +
                sysTime.minute() +
                ' ' +
                sysTime.hour() +
                ' ' +
                sysTime.day() +
                ' ' +
                sysTime.month() +
                ' ? ' +
                sysTime.year();
            System.schedule('IndexMetadataJob', cronExpression, imJob);
        }
    }

    global void execute(Database.BatchableContext bContext, List<User_Story__c> scope) {
        execute(bContext, (List<SObject>) scope);
    }

    public void execute(Database.BatchableContext bContext, List<SObject> sList) {
        String status = enableStopIdxMetadata() ? '' : checkPotentialConflict == true ? 'Potential Conflict' : null;
        if (status != null) {
            List<User_Story_Metadata__c> scope = (List<User_Story_Metadata__c>) sList;
            for (User_Story_Metadata__c usM : scope) {
                usM.Status__c = status;
            }
            Utilities.Secure_DML(scope, Utilities.DML_Action.UPD, schema.SObjectType.User_Story_Metadata__c);
        } else {
            // Project Trigger Helper  && // Attachment Trigger Helper
            Map<Id, User_Story__c> scope = new Map<Id, User_Story__c>((List<User_Story__c>) sList);
            Map<String, User_Story_Metadata__c> usMetadataByUniqueId = getUsMetadata(scope.keySet());
            Utilities.Secure_DML(
                usMetadataByUniqueId.values(),
                Utilities.DML_Action.UPS,
                schema.SObjectType.User_Story_Metadata__c,
                schema.SObjectType.User_Story_Metadata__c.fields.Unique_ID__c
            );
        }
    }

    global void finish(Database.BatchableContext bContext) {
        if (checkPotentialConflict != true) {
            //Entry only once
            IndexMetadataJob imJob = new IndexMetadataJob();
            imJob.storyIds = storyIds;
            imJob.checkPotentialConflict = true;
            Database.executebatch(imJob);
        }
    }

    private Set<String> apiNames(Set<Id> ids) {
        Set<String> mdapiNames = new Set<String>();
        for (User_Story_Metadata__c record : new UserStoriesMetadataSelector().byStoryIdsIndexingEnabled(ids)) {
            mdapiNames.add(record.Metadata_API_Name__c);
        }
        return mdapiNames;
    }

    private Set<String> namesByApiName(Set<String> mdapiNames) {
        Set<String> groupedMdapiNames = new Set<String>();
        AggregateResult[] groupedResults = [
            SELECT Metadata_API_Name__c, User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c, COUNT(Id)
            FROM User_Story_Metadata__c
            WHERE
                Metadata_API_Name__c IN :mdapiNames
                AND User_Story__r.Project__r.Index_Metadata__c = TRUE
                AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
                AND (User_Story__r.Platform__c = NULL
                OR User_Story__r.Platform__c = 'Salesforce')
            GROUP BY Metadata_API_Name__c, User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c
            HAVING COUNT(Id) > 1
        ];
        for (AggregateResult ar : groupedResults) {
            groupedMdapiNames.add(String.valueOf(ar.get(Schema.SObjectType.User_Story_Metadata__c.fields.Metadata_API_Name__c.getName())));
        }
        return groupedMdapiNames;
    }

    private Set<String> namesByEmptyStatus() {
        Set<String> groupedMdapiNames = new Set<String>();
        AggregateResult[] groupedResults = [
            SELECT Metadata_API_Name__c, User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c, COUNT(Id)
            FROM User_Story_Metadata__c
            WHERE
                Status__c = ''
                AND User_Story__r.Project__r.Index_Metadata__c = TRUE
                AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
                AND (User_Story__r.Platform__c = NULL
                OR User_Story__r.Platform__c = 'Salesforce')
            GROUP BY Metadata_API_Name__c, User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c
            HAVING COUNT(Id) > 1
        ];
        for (AggregateResult ar : groupedResults) {
            groupedMdapiNames.add(String.valueOf(ar.get(Schema.SObjectType.User_Story_Metadata__c.fields.Metadata_API_Name__c.getName())));
        }
        return groupedMdapiNames;
    }

    private Map<String, User_Story_Metadata__c> getUsMetadata(Set<Id> usIds) {
        Map<String, User_Story_Metadata__c> usMetadataByUniqueId = new Map<String, User_Story_Metadata__c>();
        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
        Map<String, User_Story_Metadata__c> existingUSMetadata = checkForExistingUSMetadata(usIds);
        for (Attachment att : new AttachmentsSelector().byParentIdAndName(usIds, new Set<String>{ 'MetaData', 'Delete MetaData', 'Git MetaData' })) {
            try {
                String jsonInput = att.Body.toString();
                List<Object> objList = (List<Object>) JSON.deserializeUntyped(jsonInput);
                for (Object obj : objList) {
                    Map<String, Object> objectMap = (Map<String, Object>) obj;
                    if (!objectMap.containsKey('t') || !objectMap.containsKey('n')) {
                        continue; // malformed JSON node in the (git) metadata attachment so skip
                    }
                    User_Story_Metadata__c usMetadata = prepareUSMetadata(objectMap, globalDesc, att);
                    if (!existingUSMetadata.containsKey(usMetadata.Unique_ID__c)) {
                        usMetadataByUniqueId.put(usMetadata.Unique_ID__c, usMetadata);
                    }
                }
            } catch (Exception e) {
                Logger.debug(
                    att.Id,
                    'IndexMetadataJob.getUsMetadata',
                    'ERROR while parsing attachment ' +
                    att.Name +
                    ' - ' +
                    att.Id +
                    ' exception: ' +
                    e.getMessage() +
                    e.getLineNumber(),
                    ''
                );
            }
        }
        return usMetadataByUniqueId;
    }

    private User_Story_Metadata__c prepareUSMetadata(Map<String, Object> objectMap, Map<String, Schema.SObjectType> globalDesc, Attachment att) {
        User_Story_Metadata__c usMetadata = new User_Story_Metadata__c();
        usMetadata.User_Story__c = att.ParentId;
        // In order to make overlap awareness work for Vlocity metadata we need API Name of their metadata
        //However we have the label which is equal to API_Name+(ID)
        //So below if condition removes the id part from the Vlocity metadata for overlap awareness
        if (objectMap.containsKey('n') && objectMap.containsKey('t')) {
            if (objectMap.get('n').toString().endsWith(')') && !globalDesc.containsKey(objectMap.get('t').toString())) {
                usMetadata.Metadata_API_Name__c = objectMap.get('t') + '.' + objectMap.get('n');
                usMetadata.Metadata_API_Name__c = usMetadata.Metadata_API_Name__c.left(255);
                usMetadata.Metadata_API_Name__c = usMetadata.Metadata_API_Name__c.replaceFirst('^(.+) \\([a-zA-Z0-9]{18}\\)$', '$1');
            } else {
                usMetadata.Metadata_API_Name__c = objectMap.get('t') + '.' + objectMap.get('n');
                usMetadata.Metadata_API_Name__c = usMetadata.Metadata_API_Name__c.left(255);
            }
        }

        usMetadata.Unique_ID__c = att.ParentId + (att.Name == DELETEMETADATA ? ' _delete_' : '_') + usMetadata.Metadata_API_Name__c;
        usMetadata.Unique_ID__c = usMetadata.Unique_ID__c.left(255);
        usMetadata.Name = att.Parent.Name + (att.Name == DELETEMETADATA ? 'Delete ' : ' ') + usMetadata.Metadata_API_Name__c;
        usMetadata.Name = usMetadata.Name.left(80);
        usMetadata.Type__c = usMetadata?.Name?.split(' ')[1]?.split('\\.')[0];
        usMetadata.Last_Commit_Date__c = System.now();
        return usMetadata;
    }

    private Map<String, User_Story_Metadata__c> checkForExistingUSMetadata(Set<Id> usIds) {
        Map<String, User_Story_Metadata__c> usMetadataByUniqueId = new Map<String, User_Story_Metadata__c>();
        for (User_Story_Metadata__c usMetadata : new UserStoryMetadataSelector().byUserStoryIds(usIds)) {
            usMetadataByUniqueId.put(usMetadata.Unique_ID__c, usMetadata);
        }
        return usMetadataByUniqueId;
    }

    private Boolean enableStopIdxMetadata() {
        return zeroizePotentialConflicts == true && checkPotentialConflict == false;
    }

    private Boolean disableStopIdxMetadata() {
        return zeroizePotentialConflicts == true && checkPotentialConflict == true;
    }

    private Boolean isProjectBased() {
        return null == storyIds && checkPotentialConflict != true;
    }

    private Boolean isAttachmentBased() {
        return null != storyIds && checkPotentialConflict != true;
    }
}