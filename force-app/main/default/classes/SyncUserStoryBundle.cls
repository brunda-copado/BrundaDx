public with sharing class SyncUserStoryBundle {
    private Map<Id, User_Story__c> parentUSBById;
    private static final Set<Schema.SObjectField> FIELDS_TO_SYNC = getFields();

    // CTOR

    public SyncUserStoryBundle(List<User_Story__c> stories, Map<Id, User_Story__c> old) {
        this.parentUSBById = new Map<Id, User_Story__c>(filterUSB(stories, old));
    }

    // PUBLIC

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void sync() {
        List<User_Story__c> childUStoUpdate = new List<User_Story__c>();

        if (!parentUSBById.isEmpty()) {
            for (Bundled_Story__c junction : new BundledStorySelector().byParentUSBIds(parentUSBById.keySet())) {
                childUStoUpdate.add(syncedStory(junction.User_Story__c, parentUSBById.get(junction.Package_Version__r.User_Story__c)));
            }
        }

        // Note: Trigger Context
        update childUStoUpdate;
    }

    // PRIVATE

    private User_Story__c syncedStory(Id childUSId, User_Story__c parentUSB) {
        User_Story__c result = new User_Story__c(Id = childUSId);
        try {
            for (Schema.SObjectField field : FIELDS_TO_SYNC) {
                result.put(field, parentUSB.get(field));
            }
        } catch (Exception e) {
            parentUSB.addError(Label.SyncBundleError + ' ' + e.getMessage());
        }
        return result;
    }

    private List<User_Story__c> filterUSB(List<User_Story__c> stories, Map<Id, User_Story__c> old) {
        List<User_Story__c> result = new List<User_Story__c>();
        for (User_Story__c story : stories) {
            if (UserStories.isBundle(story) && !isStatusCancelled(story) && isChanged(story, old.get(story.Id))) {
                result.add(story);
            }
        }
        return result;
    }

    private Boolean isStatusCancelled(User_Story__c story) {
        return story.Status__c == 'Cancelled';
    }

    private Boolean isChanged(User_Story__c newStory, User_Story__c oldStory) {
        Boolean result = false;

        for (Schema.SObjectField field : FIELDS_TO_SYNC) {
            if (newStory.get(field) != oldStory.get(field)) {
                result = true;
                break;
            }
        }

        return result;
    }

    private static Set<Schema.SObjectField> getFields() {
        Set<Schema.SObjectField> result = new Set<Schema.SObjectField>{
            User_Story__c.Status__c,
            User_Story__c.Environment__c,
            User_Story__c.Org_Credential__c
        };

        for (Schema.FieldSetMember member : Schema.SObjectType.User_Story__c.fieldSets.Bundle_Sync_Fields.getFields()) {
            result.add(member.getSObjectField());
        }

        return result;
    }
}