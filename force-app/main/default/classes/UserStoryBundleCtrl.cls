@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class UserStoryBundleCtrl {
    private static Set<String> allMetadataNames = new Set<String>();

    public String stories { get; private set; }
    public String recordId { get; set; }
    public String namespace {
        get {
            String namespace = UserStoryBundleCtrl.class.getName().substringBefore('UserStoryBundleCtrl').removeEnd('.').toLowerCase();
            return String.isBlank(namespace) ? 'c' : namespace;
        }
    }

    // CONSTRUCTOR

    public UserStoryBundleCtrl(ApexPages.StandardSetController ctrl) {
        stories = JSON.serialize(selectedRecordIds(ctrl));
    }

    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<User_Story__c> selectedStories(List<Id> ids) {
        try {
            return new UserStoriesSelector().byIdsWithBundleJunctionsInStatus(new Set<Id>(ids), new Set<String>{ 'Locked' });
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<MetaDataItem> getAllMetadata(List<String> ids, List<String> operations) {
        return metadataItems(attachments(ids, operations));
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static String createBundleRecords(
        Artifact_Version__c bundle,
        List<User_Story__c> stories,
        List<MetaDataItem> metadata,
        List<MetaDataItem> fullProfiles,
        List<MetaDataItem> destructiveChanges
    ) {
        try {
            if (platformStories(stories)) {
                Actions.CreateUserStoryBundleRequest request = new Actions.CreateUserStoryBundleRequest();
                request.packageVersion = bundle;
                request.userStoryIds = new List<Id>(new Map<Id, User_Story__c>(stories).keySet());
                Actions.CreateUserStoryBundleResult result = Actions.UserStoryBundleService.create(request);
                return result.packageVersion.Id;
            } else {
                List<String> validationErrors = new UserStoryBundleValidatorForClassic(stories, metadata, fullProfiles, destructiveChanges).execute();
                if (!validationErrors.isEmpty()) {
                    throw new ApplicationException(String.join(validationErrors, ','));
                }

                Artifact_Version__c result = new Artifact_Version__c();
                Artifact__c parentBundle = parent(bundle);
                bundle.Artifact__c = parentBundle.Id;
                result = (Artifact_Version__c) Utilities.Secure_DML(bundle, Utilities.DML_Action.INS, Schema.SObjectType.Artifact_Version__c);
                createJunctionRecords(result, stories);
                createAttachments(result, stories, metadata, fullProfiles, destructiveChanges);
                return result.Id;
            }
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    public Pagereference navigate() {
        PageReference result = new ApexPages.Action('{!List}').invoke();
        if (String.isNotBlank(recordId)) {
            result = new ApexPages.StandardController(new Artifact_Version__c(Id = recordId)).view();
            result.setRedirect(true);
        }
        return result;
    }

    // PRIVATE

    private Set<Id> selectedRecordIds(ApexPages.StandardSetController ctrl) {
        Map<Id, User_Story__c> selected = new Map<Id, User_Story__c>((List<User_Story__c>) ctrl.getSelected());
        return selected.keySet();
    }

    private static Artifact__c parent(Artifact_Version__c bundle) {
        Id recordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId();
        return (Artifact__c) Utilities.Secure_DML(
            new Artifact__c(Name = bundle.Name, RecordTypeId = recordTypeId),
            Utilities.DML_Action.INS,
            Schema.SObjectType.Artifact__c
        );
    }

    private static void createJunctionRecords(Artifact_Version__c bundle, List<User_Story__c> stories) {
        List<Bundled_Story__c> junctions = new List<Bundled_Story__c>();
        for (User_Story__c item : stories) {
            junctions.add(new Bundled_Story__c(User_Story__c = item.Id, Package_Version__c = bundle.Id));
        }
        Utilities.Secure_DML(junctions, Utilities.DML_Action.INS, Schema.SObjectType.Bundled_Story__c);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void createAttachments(
        Artifact_Version__c bundle,
        List<User_Story__c> stories,
        List<MetaDataItem> metadata,
        List<MetaDataItem> fullProfiles,
        List<MetaDataItem> destructiveChanges
    ) {
        List<Attachment> bundleAttachments = new List<Attachment>();

        if (!metadata.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Metadata', metadata));
        }

        if (!fullProfiles.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Full Profiles & Permission Sets', fullProfiles));
        }

        if (!destructiveChanges.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Destructive Changes', destructiveChanges));
        }

        List<MetaDataItem> testClasses = testOnlyAttachment(new Map<Id, User_Story__c>(stories).keySet());
        if (!testClasses.isEmpty()) {
            bundleAttachments.add(createAttachment(bundle, 'Test Classes', testClasses));
        }

        Utilities.Secure_DML(bundleAttachments, Utilities.DML_Action.INS, Schema.SObjectType.Attachment);
    }

    private static Attachment createAttachment(Artifact_Version__c bundle, String attachmentName, List<MetaDataItem> metadataItems) {
        return new Attachment(ParentId = bundle.Id, Name = attachmentName, Body = Blob.valueOf(JSON.serialize(metadataItems)));
    }

    private static List<MetaDataItem> testOnlyAttachment(Set<Id> storyIds) {
        Map<String, MetaDataItem> result = new Map<String, MetaDataItem>();
        for (Attachment record : new AttachmentsSelector().byParentIdAndName(storyIds, new Set<String>{ 'Test Classes' })) {
            // Merge the metadata to the result set.
            // Also checks if any class checked as Test only is commited, then that class will be removed from 'Test Classes' Attachment
            for (MetaDataItem metadata : metadataItems(record)) {
                if (!result.containsKey(metadata.n) && !allMetadataNames.contains(metadata.n)) {
                    result.put(metadata.n, metadata);
                }
            }
        }
        return result.values();
    }

    private static List<Attachment> attachments(List<String> ids, List<String> operations) {
        List<Attachment> result = new List<Attachment>();
        try {
            result = [
                SELECT Id, Body
                FROM Attachment
                WHERE
                    Name IN ('Metadata', 'Git Deletion')
                    AND ParentId IN (
                        SELECT Snapshot_Commit__c
                        FROM User_Story_Commit__c
                        WHERE
                            User_Story__r.Id IN :ids
                            AND Snapshot_Commit__r.Git_Operation__c = :operations
                            AND Snapshot_Commit__r.Status__c = 'Complete'
                    )
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];
        } catch (System.QueryException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return result;
    }

    @SuppressWarnings('PMD.CognitiveComplexity')
    private static List<MetaDataItem> metadataItems(List<Attachment> attachments) {
        Map<String, MetaDataItem> result = new Map<String, MetaDataItem>();
        for (Attachment record : attachments) {
            for (MetaDataItem metadata : metadataItems(record)) {
                String key = metadata.t + '.' + metadata.n;
                if (!result.containsKey(key)) {
                    metadata.s = true;
                    result.put(key, metadata);
                    allMetadataNames.add(metadata.n);
                } else {
                    // If it exists, check if it has metadata.r = false, and ensure it's also false in result
                    // This is to ensure if it is not retrieve-only at least once, it must be not retrieve only.
                    if (metadata.r == null || !metadata.r) {
                        result.get(key).r = false;
                    }
                }
            }
        }
        return result.values();
    }

    private static List<MetaDataItem> metadataItems(Attachment record) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        try {
            result = (List<MetaDataItem>) JSON.deserialize(record.Body.toString(), List<MetaDataItem>.class);
        } catch (Exception ex) {
            throw new AuraHandledException('Not parsed data ' + ex.getMessage());
        }
        return result;
    }

    private static Boolean platformStories(List<User_Story__c> stories) {
        for (User_Story__c us : stories) {
            if (String.isNotBlank(us.Platform__c) && us.Platform__c != 'Salesforce') {
                return true;
            }
        }
        return false;
    }

    private class UserStoryBundleValidatorForClassic {
        private List<User_Story__c> stories;
        private List<MetaDataItem> metadata;
        private List<MetaDataItem> fullProfiles;
        private List<MetaDataItem> destructiveChanges;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        UserStoryBundleValidatorForClassic(
            List<User_Story__c> stories,
            List<MetaDataItem> metadata,
            List<MetaDataItem> fullProfiles,
            List<MetaDataItem> destructiveChanges
        ) {
            this.stories = stories;
            this.metadata = metadata;
            this.fullProfiles = fullProfiles;
            this.destructiveChanges = destructiveChanges;
        }

        public List<String> execute() {
            List<String> result = new List<String>();

            if (stories.isEmpty() || stories.size() == 1) {
                result.add(System.Label.USB_WARNING_NO_US_SELECTED);
            } else if (metadata.isEmpty() && fullProfiles.isEmpty() && destructiveChanges.isEmpty()) {
                result.add(System.Label.USB_WARNING_NO_COMMITS);
            } else {
                if (differentEnvironmentsIn(stories)) {
                    result.add(System.Label.USB_WARNING_DIFFERENT_ENVIRONMENTS);
                }
                if (differentPipelinesIn(stories)) {
                    result.add(System.Label.USB_WARNING_DIFFERENT_PIPELINES);
                }
                List<String> lockedStories = alreadyLockedStories(stories);
                if (!lockedStories.isEmpty()) {
                    result.add(System.Label.USB_ERROR_ALREADY_LOCKED_STORY + '\n\n' + String.join(lockedStories, '\n'));
                }
            }

            return result;
        }

        private Boolean differentEnvironmentsIn(List<User_Story__c> stories) {
            Boolean result = false;

            Id refEnvironment = stories.get(0).Environment__c;
            for (User_Story__c story : stories) {
                if (story.Environment__c != refEnvironment) {
                    result = true;
                    break;
                }
            }

            return result;
        }

        private Boolean differentPipelinesIn(List<User_Story__c> stories) {
            Boolean result = false;

            Id refPipeline = getPipelineRelatedTo(stories.get(0));
            for (User_Story__c story : stories) {
                if (getPipelineRelatedTo(story) != refPipeline) {
                    result = true;
                    break;
                }
            }

            return result;
        }

        private Id getPipelineRelatedTo(User_Story__c story) {
            Id result;

            if (story.Project__r.Deployment_Flow__c != null) {
                result = story.Project__r.Deployment_Flow__c;
            } else if (story.Release__r.Project__r.Deployment_Flow__c != null) {
                result = story.Release__r.Project__r.Deployment_Flow__c;
            }

            return result;
        }

        private List<String> alreadyLockedStories(List<User_Story__c> stories) {
            List<String> result = new List<String>();

            for (User_Story__c story : stories) {
                if (!story.Bundled_Stories__r.isEmpty()) {
                    result.add(story.Name);
                }
            }
            return result;
        }
    }
}