@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class PersonaDefinitionConfig {
    @AuraEnabled
    public List<ConfigEntry> permissionSets;
    @AuraEnabled
    public List<ConfigEntry> permissionSetGroups;
    @AuraEnabled
    public List<ConfigEntry> appPermissions;
    @AuraEnabled
    public List<ConfigEntry> customPermissions;
    @AuraEnabled
    public List<ConfigEntry> licenses;
    @AuraEnabled
    public List<ConfigEntry> packageLicenses;
    @AuraEnabled
    public List<Id> credentialIds;
    @AuraEnabled
    public Id publicGroupId;
    @AuraEnabled
    public String defaultCredentialAccessLevel;

    public PersonaDefinitionConfig() {
        permissionSets = new List<ConfigEntry>();
        permissionSetGroups = new List<ConfigEntry>();
        appPermissions = new List<ConfigEntry>();
        customPermissions = new List<ConfigEntry>();
        licenses = new List<ConfigEntry>();
        packageLicenses = new List<ConfigEntry>();
        credentialIds = new List<Id>();
        defaultCredentialAccessLevel = 'read';
    }

    public String getPersonaPermissionSetGroup() {
        return this.permissionSetGroups[0].name;
    }

    public String getPersonaPermissionSet() {
        return this.permissionSets[0].name;
    }

    public List<ConfigEntry> getAssignedPermissionSetGroups() {
        return (List<ConfigEntry>) slice(this.permissionSetGroups, 1, this.permissionSetGroups.size());
    }

    public List<ConfigEntry> getAssignedPermissionSets() {
        return (List<ConfigEntry>) slice(this.permissionSets, 1, this.permissionSets.size());
    }

    private static List<Object> slice(List<Object> input, Integer ge, Integer l) {
        if (ge < 0) {
            ge += input.size();
        }
        if (l < 0) {
            l += input.size();
        }
        List<Object> output = input.clone();
        for (Integer i = 0; i < ge; i++) {
            output.remove(0);
        }
        Integer elements = l - ge;
        while (output.size() > elements) {
            output.remove(elements);
        }
        return output;
    }

    public with sharing class ConfigEntry {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Boolean isStandard;

        public ConfigEntry() {
            this.isStandard = false;
        }

        public ConfigEntry name(String name) {
            this.name = name;
            return this;
        }

        public ConfigEntry isStandard() {
            this.isStandard = true;
            return this;
        }

        public Boolean equals(Object obj) {
            if (obj != null && obj instanceof ConfigEntry) {
                ConfigEntry entry = (ConfigEntry) obj;
                return name == entry.name && isStandard == entry.isStandard;
            } else {
                return false;
            }
        }
        public Integer hashCode() {
            return (name + isStandard).hashCode();
        }
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public enum PermissionType {
        PermissionSet,
        PermissionSetGroup,
        CustomPermission,
        AppPermission,
        CopadoLicense,
        PackageLicense,
        CredentialAccessLevel
    }
}