public with sharing class BundlingProcess {
    private static final Map<String, String> OPERATIONS_BY_ATTACHMENT = new Map<String, String>{
        'Metadata' => 'Commit Files',
        'Full Profiles & Permission Sets' => 'Full Profiles & Permission Sets',
        'Destructive Changes' => 'Destructive Changes'
    };
    private static final Map<String, String> ATTACHMENTS_BY_OPERATIONS = new Map<String, String>{
        'Commit Files' => 'MetaData',
        'Full Profiles & Permission Sets' => 'MetaData',
        'Destructive Changes' => 'Git Deletion'
    };

    private Map<Id, User_Story__c> childrenStoriesById = new Map<Id, User_Story__c>();
    private Set<Id> environments = new Set<Id>();
    private List<AggregateResult> pipelines;
    private User_Story__c parentStory;
    private Id bundleId;

    // CONSTRUCTOR

    public BundlingProcess(Id bundleId, User_Story__c parentStory) {
        this.childrenStoriesById = new Map<Id, User_Story__c>(new UserStoriesSelector().byBundlePackageVersions(new Set<Id>{ bundleId }));
        this.parentStory = parentStory;
        this.bundleId = bundleId;
        this.pipelines = getPipelines();
    }

    // PUBLIC

    public BundlingResult execute() {
        environmentConsistency();
        pipelineConsistency();
        insertParentStory();
        updateBundle();
        updateChildStories();
        cloneDeploymentTasks();
        return commitMetadata();
    }

    // PRIVATE

    private void insertParentStory() {
        parentStory.Is_Bundle__c = true;
        parentStory.RecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('Utility').getRecordTypeId();
        parentStory = (User_Story__c) Utilities.Secure_DML(parentStory, Utilities.DML_Action.INS, Schema.SObjectType.User_Story__c);
    }

    private List<AggregateResult> getPipelines() {
        Set<Id> projects = new Set<Id>();
        Set<Id> releases = new Set<Id>();

        for (User_Story__c story : childrenStoriesById.values()) {
            projects.add(story.Project__c);
            releases.add(story.Release__c);
            environments.add(story.Environment__c);
        }

        Set<Id> releaseProjects = (Set<Id>) Utilities.getFieldValues(
            new ReleasesSelector().byIds(releases),
            Release__c.Project__c,
            Set<Id>.class,
            false
        );

        environments.add(parentStory.Environment__c);
        projects.add(parentStory.Project__c);
        projects.addAll(releaseProjects);

        return [SELECT Deployment_Flow__c FROM Project__c WHERE Id = :projects WITH SECURITY_ENFORCED GROUP BY Deployment_Flow__c];
    }

    private void updateBundle() {
        Artifact_Version__c bundle = new Artifact_Version__c(Id = bundleId, User_Story__c = parentStory.Id, Status__c = 'Locked');

        Utilities.Secure_DML(bundle, Utilities.DML_Action.UPD, Schema.SObjectType.Artifact_Version__c);
    }

    private void updateChildStories() {
        for (User_Story__c story : childrenStoriesById.values()) {
            story.Stop_Indexing_Metadata__c = true;
            story.Exclude_From_CBM__c = true;
        }

        Utilities.Secure_DML(childrenStoriesById.values(), Utilities.DML_Action.UPD, Schema.SObjectType.User_Story__c);
    }

    private void cloneDeploymentTasks() {
        System.enqueueJob(new CloneDeploymentTasks(childrenStoriesById.values(), parentStory));
    }

    private BundlingResult commitMetadata() {
        List<Git_Org_Commit__c> commits = new List<Git_Org_Commit__c>();

        fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Git_Org_Commit__c.SObjectType, Attachment.SObjectType });

        String snapshotId = queryGitSnapshot();
        parentStory = new UserStoriesSelector().byIds(new Set<Id>{ parentStory.Id }).get(0);

        for (Attachment attachment : new AttachmentsSelector().byParentIdAndName(new Set<Id>{ bundleId }, OPERATIONS_BY_ATTACHMENT.keySet())) {
            Git_Org_Commit__c snapshotCommit = createCommit(parentStory, snapshotId, attachment.Name);
            uow.registerNew(snapshotCommit);
            commits.add(snapshotCommit);

            Attachment attachmentForBundle = attachment.clone();
            attachmentForBundle.Name = ATTACHMENTS_BY_OPERATIONS.get(snapshotCommit.Git_Operation__c);
            uow.registerNew(attachmentForBundle, Schema.Attachment.ParentId, snapshotCommit);
        }

        attachTestClasses(uow);

        uow.commitWork();

        return new BundlingResult(parentStory.Id, snapshotId, commits);
    }

    private void attachTestClasses(fflib_ISObjectUnitOfWork uow) {
        List<Attachment> testClassAttachment = new AttachmentsSelector()
            .byParentIdAndName(new Set<Id>{ bundleId }, new Set<String>{ 'Test Classes' });

        if (!testClassAttachment.isEmpty()) {
            uow.registerNew(testClassAttachment[0].clone(), Schema.Attachment.ParentId, parentStory);
        }
    }

    private Id queryGitSnapshot() {
        Id pipelineId = (Id) pipelines[0].get(Settings.ns + 'Deployment_Flow__c');
        Deployment_Flow__c pipeline = new PipelineSelector().byId(new Set<Id>{ pipelineId })[0];
        List<Git_Backup__c> snapshots = new GitSnapshotSelector()
            .byCredentialRepoSnapshotOnly(parentStory.Org_Credential__c, pipeline.Git_Repository__c);

        if (snapshots.isEmpty()) {
            throw new ApplicationException(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND);
        }

        return snapshots.get(0).Id;
    }

    private void environmentConsistency() {
        if (environments.size() != 1) {
            throw new ApplicationException(Label.USB_WARNING_DIFFERENT_ENVIRONMENTS);
        }
    }

    private void pipelineConsistency() {
        if (pipelines.size() != 1) {
            throw new ApplicationException(Label.USB_WARNING_DIFFERENT_PIPELINES);
        }
    }

    private Git_Org_Commit__c createCommit(User_Story__c parentStory, String snapshotId, String attachmentName) {
        return new Git_Org_Commit__c(
            Commit_Message__c = parentStory.Name + ': ' + parentStory.User_Story_Title__c + ' Bundle ' + attachmentName,
            Org__c = parentStory.Org_Credential__c,
            Git_Backup__c = snapshotId,
            Status__c = 'Pending',
            Git_Operation__c = OPERATIONS_BY_ATTACHMENT.get(attachmentName)
        );
    }

    private static List<Id> getCommitIds(List<Git_Org_Commit__c> commits) {
        List<Id> commitIds = new List<Id>();

        for (Git_Org_Commit__c snapshotCommit : commits) {
            commitIds.add(snapshotCommit.Id);
        }

        return commitIds;
    }

    //INNER

    public class BundlingResult {
        @AuraEnabled
        public Id storyId;

        @AuraEnabled
        public List<Id> commitIds;

        @AuraEnabled
        public Id snapshotId;

        @AuraEnabled
        public Boolean isPlatform;

        public BundlingResult(Id storyId, Id snapshotId, List<Git_Org_Commit__c> commits) {
            this(storyId, snapshotId, getCommitIds(commits));
        }

        public BundlingResult(Id storyId, Id snapshotId, List<Id> commitIds) {
            this.storyId = storyId;
            this.commitIds = commitIds;
            this.snapshotId = snapshotId;
            this.isPlatform = false;
        }

        public BundlingResult isPlatform() {
            this.isPlatform = true;
            return this;
        }
    }
}