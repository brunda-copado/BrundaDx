public with sharing class PerformUserStoryCallout implements Queueable, Database.AllowsCallouts {
    private Id storyId;
    private Id commitId;
    private String actionName;

    // CONSTRUCTORS

    public PerformUserStoryCallout(Id storyId, Id commitId, String actionName) {
        this.storyId = storyId;
        this.commitId = commitId;
        this.actionName = actionName;
    }

    // PUBLIC

    public void execute(QueueableContext qc) {
        try {
            User_Story__c story = new UserStoriesSelector().byIds(new Set<Id>{ storyId }).get(0);
            Git_Org_Commit__c snapshotCommit = new SnapshotCommitsSelector().byIds(new Set<Id>{ commitId }).get(0);
            new HerokuCallout(getUrl(story, snapshotCommit), HttpMethod.GET)
                .default()
                .request();
        } catch (Exception ex) {
            notifyViaEmail(ex);
        }
    }

    // PRIVATE

    private String getUrl(User_Story__c story, Git_Org_Commit__c snapshotCommit) {
        return new Settings().urlBase +
                    EncodingUtil.urlEncode(actionName, 'UTF-8') +
                    '/' + snapshotCommit.Id +
                    Settings.generic_heroku_params +
                    '&userStoryId=' + story.Id +
                    '&orgId=' + story.Org_Credential__c +
                    '&gitBackupId=' + snapshotCommit.Git_Backup__c +
                    '&mainBranch=' + getMainBranch(story) +
                    '&message=' + EncodingUtil.urlEncode(snapshotCommit.Commit_Message__c, 'UTF-8') +
                    '&type=' + EncodingUtil.urlEncode(getCommitType(snapshotCommit.Git_Operation__c).trim(), 'UTF-8');
    }

    private String getMainBranch(User_Story__c story) {
        String result = 'master';

        if (String.isNotBlank(story.Base_Branch__c)) {
            result = story.Base_Branch__c;
        } else if (String.isNotBlank(story.Release__r.Base_Branch__c)) {
            result = story.Release__r.Base_Branch__c;
        } else if (String.isNotBlank(story.Project__r.Deployment_Flow__r.Main_Branch__c)) {
            result = story.Project__r.Deployment_Flow__r.Main_Branch__c;
        }

        return result;
    }

    private String getCommitType(String gitOperation) {
        return (gitOperation == 'Destructive Changes') ? 'GitDeletion'
            : (gitOperation == 'Full Profiles & Permission Sets') ? 'FullProfilePermissionSets'
                : gitOperation;
    }

    private void notifyViaEmail(Exception ex) {
        Messaging.SingleEmailMessage message = Utilities.createEmail(
            new List<String>{ UserInfo.getUserId() },
            Label.USB_ERROR_EMAIL_SUBJECT,
            messageFromTemplate(ex)
        );

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
    }

    private String messageFromTemplate(Exception ex) {
        List<EmailTemplate> template = new EmailTemplatesSelector().byDevName('GenericNotification');
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template[0].Id, null, null);

        return (message.htmlbody == null) ? ''
            : message.htmlbody.replace('emailBody', ex.getMessage() + '<br/>' + ex.getStackTraceString())
                .replace('emailTitle', Label.USB_ERROR_EMAIL_TITLE);
    }
}