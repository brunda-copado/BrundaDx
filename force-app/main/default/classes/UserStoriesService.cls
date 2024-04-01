public with sharing class UserStoriesService {
    private Set<Id> userStoryIds;

    private final Map<Id, User_Story__c> userStoriesById {
        get {
            if (userStoriesById == null) {
                userStoriesById = new Map<Id, User_Story__c>(new UserStoriesSelector().byIds(this.userStoryIds));
            }
            return userStoriesById;
        }
        set;
    }

    private final Map<Id, List<User_Story_Data_Commit__c>> userStoryDataCommitsByUserStory {
        get {
            if (userStoryDataCommitsByUserStory == null) {
                userStoryDataCommitsByUserStory = new UserStoryDataCommitsSelector().byUserStory(this.userStoryIds);
            }
            return userStoryDataCommitsByUserStory;
        }
        set;
    }

    public UserStoriesService(Set<Id> userStoryIds) {
        this.userStoryIds = userStoryIds;
    }

    public User_Story__c getUserStory(Id userStoryId) {
        return this.userStoriesById.get(userStoryId);
    }

    public List<User_Story_Data_Commit__c> getDataCommits(Id userStoryId) {
        return this.userStoryDataCommitsByUserStory.containsKey(userStoryId)
            ? this.userStoryDataCommitsByUserStory.get(userStoryId)
            : new List<User_Story_Data_Commit__c>();
    }

}