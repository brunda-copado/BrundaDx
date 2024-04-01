@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CyclomaticComplexity,PMD.ExcessivePublicCount')
public with sharing class WorkPushServices implements CLIInterface {
    private List<Attachment> attachments = new List<Attachment>();
    private Map<String, Metadata> retrivablesByFilePath = new Map<String, Metadata>();
    private Map<String, Metadata> retrivablesByFileName = new Map<String, Metadata>();
    private Map<String, List<Metadata>> retrievablesByCommitId = new Map<String, List<Metadata>>();

    private Work work;
    private User_Story__c userStory;
    private DxFormatConvertResponse dxResponse;

    // PUBLIC

    public String run(CliProxy.CLIWrapper record) {
        WorkPushDataWrapper result;

        checkAccess();

        work = (Work) JSON.deserialize(record.body, Work.class);
        userStory = userStory();

        if(isSalesforcePlatform()) {
            saveCommits();
            result = new WorkPushDataWrapper(CliSfDataWrapper.StatusResult.OK.name(), dxResponse?.errors);
        } else {
            CommitWrapper latestCommit = work.commitList[0];
            Integer gitCommitCount = [SELECT count() FROM Git_Org_Commit__c WHERE Commit_Id__c = :latestCommit.commitId WITH SECURITY_ENFORCED];

            // NOTE: This commit is already done in salesforce from a different mode(UI/webhook...)
            if(gitCommitCount > 0) {
                result = new WorkPushDataWrapper(CliSfDataWrapper.StatusResult.OK.name(), null);
            } else {
                CommitAction.Request request = new CommitAction.Request();
                request.executeCommit = false;
                request.changes = work.changes;
                request.userStoryId = userStory.Id;
                request.commitId = latestCommit.commitId;
                request.message = latestCommit.commitMessage;

                List<CommitAction.Response> responses = CommitAction.commitChanges(new List<CommitAction.Request> { request });

                result = new WorkPushDataWrapper(responses[0].JobExecution);
            }
        }

        return (JSON.serialize(result));
    }


    // PRIVATE

    private void saveCommits() {
        FileToRetWrapper fileWrapper = new FileToRetWrapper(filenameSet(work.commitList), work.projectJson);

        dxResponse = parser().retrivables(fileWrapper, sourceFormat());
        retrivablesByFilePath = byFileName(dxResponse.response);

        Savepoint sp = Database.setSavepoint();

        try {
            Id snapshotId = snapShotId();

            List<Git_Org_Commit__c> gitCommits = asGitOrgCommit(work.commitList, snapshotId, userStory.Org_Credential__c);
            Utilities.Secure_DML(
                gitCommits,
                Utilities.DML_Action.UPS,
                Schema.SObjectType.Git_Org_Commit__c,
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Id__c
            );

            List<User_Story_Commit__c> userStoryCommits = asUserStoryCommit(gitCommits, userStory.Id);
            Utilities.Secure_DML(
                userStoryCommits,
                Utilities.DML_Action.UPS,
                Schema.SObjectType.User_Story_Commit__c,
                Schema.SObjectType.User_Story_Commit__c.fields.External_Id__c
            );

            attachments.add(attUserStoryRetrievable());
            Utilities.Secure_DML(attachments, Utilities.DML_Action.UPS, Schema.SObjectType.Attachment);
        }
        catch(Exception ex) {
            Database.rollback(sp);
            throw new CliException(ex.getMessage());
        }
    }


    private ServiceHelper parser() {
        return isSalesforcePlatform() ?
                    (ServiceHelper) (InternalServiceHelper.class.newInstance()) :
                    (ServiceHelper) (ExternalServiceHelper.class.newInstance());
    }


    private Id snapShotId() {
        List<Git_Backup__c> result;

        Id repositoryId = repositoryId();

        result = [ SELECT Id
                    FROM Git_Backup__c
                    WHERE
                        Org__c = :userStory.Org_Credential__c AND
                        Git_Repository__c = :repositoryId AND
                        Git_Snapshot_Permissions__c != 'Allow Snapshots Only' WITH SECURITY_ENFORCED
                    LIMIT 1];

        return result.isEmpty() ? null : result[0].Id;
    }


    private List<Git_Org_Commit__c> asGitOrgCommit(List<CommitWrapper> commits, String gitSnapshotId, String orgCredentialId) {
        List<Git_Org_Commit__c> result = new List<Git_Org_Commit__c>();

        for(CommitWrapper comm : commits) {
            retrievablesByCommitId.put(comm.commitId, retrievables(comm));

            Git_Org_Commit__c orgCommit = new Git_Org_Commit__c();
            orgCommit.Status__c = 'Complete';
            orgCommit.Org__c = orgCredentialId;
            orgCommit.Commit_Id__c = comm.commitId;
            orgCommit.Git_Backup__c = gitSnapshotId;
            orgCommit.Commit_Message__c = comm.commitMessage;
            orgCommit.Commit_Date__c = Datetime.valueOfGmt(comm.commitDate);

            result.add(orgCommit);
        }

        return result;
    }


    private List<User_Story_Commit__c> asUserStoryCommit(List<Git_Org_Commit__c> snapshots, String userStoryId) {
        List<User_Story_Commit__c> result = new List<User_Story_Commit__c>();

        String attachmentName = isSalesforcePlatform() ? 'METADATA' : 'ExternalMetaData';

        for(Git_Org_Commit__c snapshot : snapshots) {
            User_Story_Commit__c storyCommit = new User_Story_Commit__c();
            storyCommit.External_Id__c = userStoryId + '_' + snapshot.Commit_Id__c;
            storyCommit.Snapshot_Commit__c = snapshot.Id;
            storyCommit.User_Story__c = userStoryId;
            result.add(storyCommit);

            Attachment commitAttachment = new Attachment();
            commitAttachment.Name = attachmentName;
            commitAttachment.ParentId = snapshot.Id;
            commitAttachment.Body = Blob.valueOf(JSON.serialize(retrievablesByCommitId.get(snapshot.Commit_Id__c), true));

            attachments.add(commitAttachment);

            Attachment repositoryAttachment = new Attachment();
            repositoryAttachment.Name = snapshot.Commit_Id__c + '.json';
            repositoryAttachment.ParentId = repositoryId();
            repositoryAttachment.Body = commitAttachment.Body;

            attachments.add(repositoryAttachment);
        }

        return result;
    }


    private List<Metadata> retrievables(CommitWrapper comm) {
        List<Metadata> result = new List<Metadata>();

        for(String file : comm.commitFiles) {
            if(retrivablesByFilePath.containsKey(file) && retrivablesByFilePath.get(file) != null) {
                String commitDateStr = String.valueOfGmt(Datetime.valueOfGmt(comm.commitDate));
                Metadata metadata = retrivablesByFilePath.get(file);
                metadata.s = false;
                metadata.d = commitDateStr;
                metadata.b = lastModifiedBy();
                metadata.cd = commitDateStr;
                metadata.cb = comm.commitAuthor;
                metadata.r = false;
                metadata.snapshotCommitId = comm.commitId;
                metadata.cmm = 'added';

                result.add(metadata);
                retrivablesByFileName.put(metadata.n + metadata.t, metadata);
            }
        }

        return result;
    }


    private void checkAccess() {
        // OLS check
        List<String> checkOlsList = CliSecurityService.checkOLS(
            new List<String>{ Schema.SObjectType.User_Story__c.getName(), Schema.SObjectType.Git_Backup__c.getName() }
        );

        if(!checkOlsList.isEmpty()) {
            throw new CliException('Insufficient privileges to ' + checkOlsList);
        }

        // FLS check
        List<String> checkFlsList = new List<String>();
        List<String> checkFlsSnapShotCommit = CliSecurityService.checkFLS(
            Schema.SObjectType.Git_Org_Commit__c.getName(),
            new List<String> {
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Id__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Message__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Git_Backup__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Org__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Status__c.getName(),
                Schema.SObjectType.Git_Org_Commit__c.fields.Commit_Date__c.getName()
            },
            Utilities.DML_Action.INS
        );

        if(!checkFlsSnapShotCommit.isEmpty()) {
            checkFlsList.addAll(checkFlsSnapShotCommit);
        }

        List<String> checkFlsUserStoryCommit = CliSecurityService.checkFLS(
            Schema.SObjectType.User_Story_Commit__c.getName(),
            new List<String>{
                Schema.SObjectType.User_Story_Commit__c.fields.External_Id__c.getName(),
                Schema.SObjectType.User_Story_Commit__c.fields.Snapshot_Commit__c.getName(),
                Schema.SObjectType.User_Story_Commit__c.fields.User_Story__c.getName()
            },
            Utilities.DML_Action.INS
        );

        if(!checkFlsUserStoryCommit.isEmpty()) {
            checkFlsList.addAll(checkFlsUserStoryCommit);
        }

        if(!checkFlsList.isEmpty()) {
            throw new CliException(Label.Insufficient_Access + checkFlsList);
        }
    }


    private Set<String> filenameSet(List<CommitWrapper> commitList) {
        Set<String> result = new Set<String>();

        for(CommitWrapper comm : commitList) {
            result.addAll(comm.commitFiles);
        }

        return result;
    }


    private User_Story__c userStory() {

        List<User_Story__c> userStories = [SELECT Id, Name, Platform__c, Project__r.Deployment_Flow__r.Git_Repository__c, Project__r.Deployment_Flow__r.Git_Repository__r.Source_Format__c, Developer__r.Name, Owner.Name, Org_Credential__c
                                            FROM User_Story__c
                                            WHERE Id = :work.userStory WITH SECURITY_ENFORCED];

        if(userStories.isEmpty()) {
            throw new CliException(Label.USER_STORY_NOT_SET);
        }

        return userStories[0];
    }


    private Map<String, Metadata> byFileName(List<Retrievable> retrievables) {
        Map<String, Metadata> result = new Map<String, Metadata>();

        for(Retrievable retrievable : retrievables) {
            result.put(retrievable.filePath, retrievable.metaData);
        }

        return result;
    }


    private Attachment attUserStoryRetrievable() {
        Attachment result = new Attachment();

        Attachment gitMetadataAttachment = gitMetadataAttachment();

        if(gitMetadataAttachment != null) {
            updateExistingRetrivables(gitMetadataAttachment);
        }


        if(gitMetadataAttachment != null) {
            result.Id = gitMetadataAttachment.Id;
        }
        else {
            result.ParentId = userStory.Id;
            result.Name = 'Git MetaData';
        }

        result.Body = Blob.valueOf(JSON.serialize(retrivablesByFileName.values(), true));

        return result;
    }


    private void updateExistingRetrivables(Attachment existingAttachment) {
        List<Metadata> existingRetrivables = (List<Metadata>) JSON.deserialize(existingAttachment.Body.toString(), List<Metadata>.class);

        for(Metadata existingRetrivable : existingRetrivables) {
            String key = existingRetrivable.n + existingRetrivable.t;
            if(retrivablesByFileName.containsKey(key)) {
                Metadata newRetrivable = retrivablesByFileName.get(key);
                existingRetrivable.d = newRetrivable.d;
                existingRetrivable.b = newRetrivable.b;
                existingRetrivable.cmm = 'updated';
            }

            retrivablesByFileName.put(key, existingRetrivable);
        }
    }


    private Attachment gitMetadataAttachment() {
        List<Attachment> result = [SELECT Id, Body
                                    FROM Attachment
                                    WHERE Name = 'Git MetaData' AND ParentId = :userStory.Id WITH SECURITY_ENFORCED
                                    LIMIT 1 ];


        return result.isEmpty() ? null : result[0];
    }


    private Boolean isSalesforcePlatform() {
        return (String.isBlank(userStory.Platform__c) || userStory.Platform__c == 'Salesforce');
    }


    private String lastModifiedBy() {
        return (userStory.Developer__c != null ? userStory.Developer__r.Name : userStory.Owner.Name);
    }


    private Id repositoryId() {
        return userStory.Project__r.Deployment_Flow__r.Git_Repository__c;
    }


    private String sourceFormat() {
        String result = null;

        if(isSalesforcePlatform()) {
            result = String.isNotBlank(userStory.Project__r?.Deployment_Flow__r?.Git_Repository__r?.Source_Format__c)
                ? userStory.Project__r.Deployment_Flow__r.Git_Repository__r?.Source_Format__c
                : 'MetaData';
        }
        else {
            result = userStory.Platform__c;
        }

        return result;
    }


    // INNER


    public interface ServiceHelper {
        DxFormatConvertResponse retrivables(FileToRetWrapper retWrapper, String sourceFormat);
    }


    public with sharing class InternalServiceHelper implements ServiceHelper {
        public DxFormatConvertResponse retrivables(FileToRetWrapper retWrapper, String sourceFormat) {
            DxFormatConvertResponse result = DeployAPI.fileToRet(retWrapper, sourceFormat);

            return result;
        }
    }


    public with sharing class ExternalServiceHelper implements ServiceHelper {
        public DxFormatConvertResponse retrivables(FileToRetWrapper retWrapper, String sourceFormat) {

            List<Retrievable> result = new List<Retrievable>();

            for(String path : retWrapper.fileList) {
                Retrievable ret = new Retrievable();
                ret.metaData = metadata(path, sourceFormat);
                ret.filePath = path;

                result.add(ret);
            }

            return new DxFormatConvertResponse(result);
        }


        private Metadata metadata(String path, String type) {
            Metadata result = new Metadata();
            result.n = path.contains('/') ? path.substringAfterLast('/') : path;
            result.t = type;

            return result;
        }
    }


    @TestVisible
    private class Work {
        @TestVisible
        private String userStory;
        @TestVisible
        private String projectJson;
        @TestVisible
        private List<CommitWrapper> commitList;
        @TestVisible
        private List<CommitAction.Change> changes;
    }


    @TestVisible
    private class CommitWrapper {
        @TestVisible
        private String commitId;
        @TestVisible
        private String commitMessage;
        @TestVisible
        private String commitDate;
        @TestVisible
        private String commitAuthor;
        @TestVisible
        private List<String> commitFiles;
    }


    public class FileToRetWrapper {
        public Set<String> fileList;
        public String projectJson;

        public FileToRetWrapper(Set<String> fileList, String projectJson) {
            this.fileList = fileList;
            this.projectJson = projectJson;
        }
    }


    public class Retrievable {
        public String filePath;
        public Metadata metaData;
    }


    public class Metadata {
        public String n;
        public Boolean s;
        public String d;
        public String b;
        public String cb;
        public Boolean r;
        public String t;
        public String cd;
        public String cmm;
        public String vk;
        public String snapshotCommitId;
    }

    public class DxFormatConvertResponse {
        private List<Retrievable> response;
        private Boolean hasErrors;
        private List<FormatError> errors;

        public DxFormatConvertResponse(List<Retrievable> response) {
            this.response = response;
        }
    }


    private class FormatError {
        private String filePath;
        private final String errorKey;
        private final String errorMessage;
    }


    @TestVisible
    private class WorkPushDataWrapper extends CliSfDataWrapper {
        @TestVisible
        private List<FormatError> errors;
        private JobExecution__c jobExecution;

        private WorkPushDataWrapper(String stat, List<FormatError> errList) {
            status = stat;
            errors = errList;
        }

        private WorkPushDataWrapper(JobExecution__c jobExecution) {
            this.jobExecution = jobExecution;
            status = CliSfDataWrapper.StatusResult.OK.name();
        }
    }
}