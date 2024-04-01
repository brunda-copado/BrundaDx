public with sharing class UserStories extends fflib_SObjectDomain {

    public static Boolean bypassTrigger = false;

    // CONSTRUCTOR

    public UserStories(List<User_Story__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new CancelUserStoryBundle(records, (Map<Id, User_Story__c>) old).applyDefaults();
        new ValidateUserStoryBundle(records, (Map<Id, User_Story__c>) old).validateChildUS();
    }

    public override void onAfterUpdate(Map<Id, SObject> old) {
        new SyncUserStoryBundle(records, (Map<Id, User_Story__c>) old).sync();
        new CancelUserStoryBundle(records, (Map<Id, User_Story__c>) old).undoBundling();
    }

    // HELPER

    public static Boolean isBundle(User_Story__c story) {
        return story.Is_Bundle__c && isRTUtility(story);
    }

    public static Boolean isRTUtility(User_Story__c story) {
        return story.RecordTypeId == Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('Utility').getRecordTypeId();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new UserStories(records);
        }
    }
}