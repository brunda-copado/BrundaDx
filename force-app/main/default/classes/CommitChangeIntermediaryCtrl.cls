public with sharing class CommitChangeIntermediaryCtrl {
    @TestVisible
    private static final string USERSTORYCOMMITPAGE = 'UserStoryCommitPage';
    @TestVisible
    private static final string DEFAULTPAGENAME = 'User_Story_Commit';

    //PUBLIC

    @AuraEnabled
    public static string getCommitPageNameFromSettings(Id userstoryId) {
        String result = Settings.ns + DEFAULTPAGENAME;
        try {
            List<User_Story__c> userstories = new UserStoriesSelector().byIdsForMulticloud(new Set<Id>{ userstoryId });
            if (!userstories.isEmpty()) {
                User_Story__c userStory = userstories[0];
                List<ExtensionKeyValueSetting__mdt> userStoryCommitPageSettings = new ExtensionKeyValueSettingsSelector()
                    .byPlatformAndKey(userStory?.Platform__c, USERSTORYCOMMITPAGE);
                result = !userStoryCommitPageSettings.isEmpty() ? userStoryCommitPageSettings[0].Value__c : result;
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }

        return result;
    }
}