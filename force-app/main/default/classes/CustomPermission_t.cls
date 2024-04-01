@IsTest
public with sharing class CustomPermission_t extends DomainBuilder {
    public CustomPermission_t() {
        super(SetupEntityAccess.SObjectType);
    }

    public CustomPermission_t setPermissionSetId(Id permissionSetId) {
        return (CustomPermission_t) set(SetupEntityAccess.ParentId, permissionSetId);
    }

    public CustomPermission_t userStoryBundles() {
        set(
            SetupEntityAccess.SetupEntityId,
            [SELECT Id FROM CustomPermission WHERE DeveloperName = :CustomPermissionConstants.USER_STORY_BUNDLE_CUSTOM_PERMISSION LIMIT 1]
            .Id
        );
        return this;
    }

    public CustomPermission_t removeMetadataFromPromotion() {
        set(
            SetupEntityAccess.SetupEntityId,
            [
                SELECT Id
                FROM CustomPermission
                WHERE DeveloperName = :CustomPermissionConstants.REMOVE_METADATA_FROM_PROMOTION_CUSTOM_PERMISSION
                LIMIT 1
            ]
            .Id
        );
        return this;
    }
}