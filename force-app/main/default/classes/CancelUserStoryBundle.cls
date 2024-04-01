public with sharing class CancelUserStoryBundle {
    private static final String CANCELLED_STATUS = 'Cancelled';

    private Map<Id, User_Story__c> parentUSBById;
    private Map<Id, Artifact_Version__c> parentPackageVersionsById;
    private ObjectMode mode;

    // CTOR

    public CancelUserStoryBundle(List<User_Story__c> stories, Map<Id, User_Story__c> old) {
        this.parentUSBById = new Map<Id, User_Story__c>(filterUSB(stories, old));
        this.mode = ObjectMode.USER_STORY;
    }

    public CancelUserStoryBundle(List<Artifact_Version__c> packageVersions, Map<Id, Artifact_Version__c> old) {
        this.parentPackageVersionsById = new Map<Id, Artifact_Version__c>(filterUSB(packageVersions, old));
        this.mode = ObjectMode.PACKAGE_VERSION;
    }

    // PUBLIC

    public void applyDefaults() {
        for (User_Story__c parentUSB : parentUSBById.values()) {
            parentUSB.Stop_Indexing_Metadata__c = true;
            parentUSB.Exclude_From_CBM__c = true;
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void undoBundling() {
        Map<Id, Artifact_Version__c> bundlesToCancelById = new Map<Id, Artifact_Version__c>();
        Map<Id, User_Story__c> userStoryBundlesToCancelById = new Map<Id, User_Story__c>();
        Map<Id, User_Story__c> childUStoUpdateById = new Map<Id, User_Story__c>();
        List<Bundled_Story__c> junctionsToDelete = new List<Bundled_Story__c>();

        // depending the mode
        List<Bundled_Story__c> bundledStories = new List<Bundled_Story__c>();
        if (this.mode == ObjectMode.USER_STORY && !parentUSBById.isEmpty()) {
            bundledStories = new BundledStorySelector().byParentUSBIds(parentUSBById.keySet());
        } else if (this.mode == ObjectMode.PACKAGE_VERSION && !parentPackageVersionsById.isEmpty()) {
            bundledStories = new BundledStorySelector().byPackageVersion(parentPackageVersionsById.keySet());
        }

        for (Bundled_Story__c junction : bundledStories) {
            // Note: Using Map to avoid duplicate Id in list error
            if (this.mode == ObjectMode.USER_STORY) {
                bundlesToCancelById.put(junction.Package_Version__c, cancelledBundle(junction.Package_Version__c));
            }
            if (this.mode == ObjectMode.PACKAGE_VERSION && junction.Package_Version__r.User_Story__c != null) {
                userStoryBundlesToCancelById.put(
                    junction.Package_Version__r.User_Story__c,
                    cancelledUserStoryBundle(junction.Package_Version__r.User_Story__c)
                );
            }
            childUStoUpdateById.put(junction.User_Story__c, unbundledChildUS(junction.User_Story__c));
            junctionsToDelete.add(junction);
        }

        // Note: Trigger Context
        // Note: as both triggers are doing the same, if we don't bypass them we will enter in a loop trying to update/delete something that was already done in previous trigger
        ArtifactVersionTriggerHandler.bypassTrigger = true;
        update bundlesToCancelById.values();
        ArtifactVersionTriggerHandler.bypassTrigger = false;

        List<User_Story__c> userStoriesToUpdate = new List<User_Story__c>();
        userStoriesToUpdate.addAll(userStoryBundlesToCancelById.values());
        userStoriesToUpdate.addAll(childUStoUpdateById.values());
        UserStories.bypassTrigger = true;
        update userStoriesToUpdate;
        UserStories.bypassTrigger = false;

        delete junctionsToDelete;
    }

    // PRIVATE

    private Artifact_Version__c cancelledBundle(Id versionId) {
        return new Artifact_Version__c(Id = versionId, Status__c = CANCELLED_STATUS);
    }

    private User_Story__c cancelledUserStoryBundle(Id userStoryId) {
        return new User_Story__c(Id = userStoryId, Status__c = CANCELLED_STATUS, Stop_Indexing_Metadata__c = true, Exclude_From_CBM__c = true, Cancellation_Reason__c = Label.Bundle_Cancellation_Reason);
    }

    private User_Story__c unbundledChildUS(Id childUSId) {
        return new User_Story__c(Id = childUSId, Stop_Indexing_Metadata__c = false, Exclude_From_CBM__c = false);
    }

    private List<User_Story__c> filterUSB(List<User_Story__c> stories, Map<Id, User_Story__c> old) {
        List<User_Story__c> result = new List<User_Story__c>();

        for (User_Story__c story : stories) {
            if (UserStories.isBundle(story) && isStatusCancelled(story, old.get(story.Id))) {
                result.add(story);
            }
        }

        return result;
    }

    private List<Artifact_Version__c> filterUSB(List<Artifact_Version__c> packageVersions, Map<Id, Artifact_Version__c> old) {
        List<Artifact_Version__c> result = new List<Artifact_Version__c>();

        for (Artifact_Version__c packageVersion : [
            SELECT Artifact__r.RecordType.DeveloperName, User_Story__r.Id, Status__c
            FROM Artifact_Version__c
            WHERE Id IN :new Map<Id, Artifact_Version__c>(packageVersions).keySet()
            WITH SECURITY_ENFORCED
        ]) {
            if (isBundle(packageVersion) && isStatusCancelled(packageVersion, old.get(packageVersion.Id))) {
                result.add(packageVersion);
            }
        }

        return result;
    }

    private Boolean isStatusCancelled(User_Story__c newStory, User_Story__c oldStory) {
        return (newStory.Status__c == CANCELLED_STATUS && newStory.Status__c != oldStory.Status__c);
    }

    private Boolean isStatusCancelled(Artifact_Version__c newPackageVersion, Artifact_Version__c oldPackageVersion) {
        return (newPackageVersion.Status__c == CANCELLED_STATUS && newPackageVersion.Status__c != oldPackageVersion.Status__c);
    }

    private Boolean isBundle(Artifact_Version__c packageVersion) {
        return packageVersion.Artifact__r.RecordType.DeveloperName == 'User_Story_Bundle';
    }

    // INNER

    private enum ObjectMode {
        USER_STORY,
        PACKAGE_VERSION
    }
}