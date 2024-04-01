@IsTest
public class UserStory extends DomainBuilder {
    public UserStory() {
        super(User_Story__c.SObjectType);
    }

    public UserStory title(String title) {
        return (UserStory) set(User_Story__c.User_Story_Title__c, title);
    }

    public UserStory status(String status) {
        return (UserStory) set(User_Story__c.Status__c, status);
    }

    public UserStory storyPoints(Integer storyPoints) {
        return (UserStory) set(User_Story__c.Story_Points_Other__c, storyPoints);
    }

    public UserStory credential(Credential credential) {
        setParent(User_Story__c.Org_Credential__c, credential);
        return this;
    }

    public UserStory credentialId(String credentialId) {
        return (UserStory) set(User_Story__c.Org_Credential__c, credentialId);
    }

    public UserStory releaseId(String releaseId) {
        return (UserStory) set(User_Story__c.Release__c, releaseId);
    }

    public UserStory environment(Environment environment) {
        setParent(User_Story__c.Environment__c, environment);
        return this;
    }

    public UserStory readyToPromote(Boolean readyToPromote) {
        return (UserStory) set(User_Story__c.Promote_Change__c, readyToPromote);
    }

    public UserStory add(UserStoryMetadata metadata) {
        metadata.setParent(User_Story_Metadata__c.User_Story__c, this);
        return this;
    }

    public UserStory featureId(Id featureId) {
        return (UserStory) set(User_Story__c.US_Feature__c, featureId);
    }

    public UserStory add(UserStoryCommit userStoryCommit) {
        userStoryCommit.setParent(User_Story_Commit__c.User_Story__c, this);
        return this;
    }

    public UserStory add(JobStep deploymentStep) {
        deploymentStep.setParent(JobStep__c.UserStory__c, this);
        return this;
    }

    public UserStory add(Test_t test) {
        test.setParent(Test__c.User_Story__c, this);
        return this;
    }
}