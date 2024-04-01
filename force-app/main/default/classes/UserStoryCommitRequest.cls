public with sharing class UserStoryCommitRequest {
    @AuraEnabled
    public Id userStoryId { get; set; }
    @AuraEnabled
    public List<UserStoryCommitChange> changes { get; set; }
    @AuraEnabled
    public Boolean recreateFeatureBranch { get; set; }
    @AuraEnabled
    public Boolean executeCommit { get; set; }
    @AuraEnabled
    public String baseBranch { get; set; }
    @AuraEnabled
    public String message { get; set; }

    public CommitAction.Request parse() {
        CommitAction.Request result = new CommitAction.Request();
        result.userStoryId = userStoryId;
        result.changes = parseChanges();
        result.recreateFeatureBranch = recreateFeatureBranch;
        result.executeCommit = executeCommit;
        result.baseBranch = baseBranch;
        result.message = message;
        return result;
    }

    private List<CommitAction.Change> parseChanges() {
        List<CommitAction.Change> result = new List<CommitAction.Change>();
        for(UserStoryCommitChange change : changes) {
            result.add(change.parse());
        }
        return result;
    }
}