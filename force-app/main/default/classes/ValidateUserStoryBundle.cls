public with sharing class ValidateUserStoryBundle {
    
    private Map<Id, User_Story__c> cancelledChildUSById;

    // CTOR

    public ValidateUserStoryBundle(List<User_Story__c> stories, Map<Id, User_Story__c> old) {
        this.cancelledChildUSById = new Map<Id, User_Story__c>( filterCancelledChildUS(stories, old) );
    }

    // PUBLIC

    public void validateChildUS() {
        validateIfBundled();
    }

    // PRIVATE

    private void validateIfBundled() {
        if (!cancelledChildUSById.isEmpty()) {
            for (
                Bundled_Story__c junction : new BundledStorySelector()
                    .byStoryIdsAndVersionStatus(cancelledChildUSById.keySet(), new Set<String>{ 'Open', 'Locked' })
            ) {
                cancelledChildUSById.get(junction.User_Story__c).addError(Label.USB_ERROR_CHILD_CANCELLATION);
            }
        }
    }


    private List<User_Story__c> filterCancelledChildUS(List<User_Story__c> stories, Map<Id, User_Story__c> old) {
        List<User_Story__c> result = new List<User_Story__c>();

        for (User_Story__c story : stories) {
            if (!UserStories.isBundle(story) && isStatusCancelled(story, old.get(story.Id))) {
                result.add(story);
            }
        }

        return result;
    }


    private Boolean isStatusCancelled(User_Story__c newStory, User_Story__c oldStory) {
        return (newStory.Status__c == 'Cancelled' && newStory.Status__c != oldStory.Status__c);
    }
}