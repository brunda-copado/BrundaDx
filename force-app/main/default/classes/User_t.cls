@IsTest
@SuppressWarnings('PMD.PropertyNamingConventions')
public with sharing class User_t extends DomainBuilder {
    private static final Map<String, Id> PROFILE_BY_NAME {
        get {
            if (PROFILE_BY_NAME == null) {
                PROFILE_BY_NAME = new Map<String, Id>();
                for (Profile profile : [SELECT Id, Name FROM Profile WHERE Name IN ('Standard User', 'System Administrator')]) {
                    PROFILE_BY_NAME.put(profile.Name, profile.Id);
                }
            }
            return PROFILE_BY_NAME;
        }
        set;
    }

    public User_t() {
        super(User.SObjectType);

        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        set(User.Alias, uniqueName.substring(18, 23));
        set(User.Email, uniqueName + '@test' + orgId + '.org');
        set(User.EmailEncodingKey, 'UTF-8');
        set(User.FirstName, 'John');
        set(User.Lastname, 'Doe');
        set(User.languagelocalekey, 'en_US');
        set(User.localesidkey, 'en_US');
        set(User.timezonesidkey, 'America/Los_Angeles');
        set(User.isActive, true);
        set(User.UserPermissionsInteractionUser, true);
        set(User.username, uniqueName + '@test' + orgId + '.org');

        standard();
    }

    public User_t alias(String alias) {
        set(User.Alias, alias);
        return this;
    }

    public User_t standard() {
        profile(PROFILE_BY_NAME.get('Standard User'));
        return this;
    }

    public User_t admin() {
        profile(PROFILE_BY_NAME.get('System Administrator'));
        return this;
    }

    public User_t profile(Id profile) {
        set(User.ProfileId, profile);
        return this;
    }

    public User_t assign(PermissionSetAssignment_t permission) {
        permission.setParent(PermissionSetAssignment.AssigneeId, this);
        return this;
    }
}