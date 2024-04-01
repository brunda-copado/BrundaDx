@IsTest
@SuppressWarnings('PMD.PropertyNamingConventions')
public with sharing class PermissionSetAssignment_t extends DomainBuilder {
    private static final Map<String, Id> PERMISSION_SET_BY_NAME {
        get {
            if (PERMISSION_SET_BY_NAME == null) {
                PERMISSION_SET_BY_NAME = new Map<String, Id>();
                for (PermissionSet permission : [
                    SELECT Id, Name
                    FROM PermissionSet
                    WHERE
                        Name IN (
                            'Copado_User',
                            'Copado_Job_Engine',
                            'Copado_Functions',
                            'Copado_Functions_User',
                            'Configure_AQF',
                            'Access_AQF',
                            'Configure_Automations',
                            'Execute_Automations',
                            'Configure_Snapshot',
                            'Persona_Management'
                        )
                ]) {
                    PERMISSION_SET_BY_NAME.put(permission.Name, permission.Id);
                }
            }
            return PERMISSION_SET_BY_NAME;
        }
        set;
    }

    public PermissionSetAssignment_t() {
        super(PermissionSetAssignment.SObjectType);
    }

    public PermissionSetAssignment_t copadoUser() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Copado_User'));
        return this;
    }

    public PermissionSetAssignment_t jobEngine() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Copado_Job_Engine'));
        return this;
    }

    public PermissionSetAssignment_t functions() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Copado_Functions'));
        return this;
    }

    public PermissionSetAssignment_t functionsUser() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Copado_Functions_User'));
        return this;
    }

    public PermissionSetAssignment_t qualityGatesAdmin() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Configure_AQF'));
        return this;
    }

    public PermissionSetAssignment_t qualityGatesReadOnly() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Access_AQF'));
        return this;
    }

    public PermissionSetAssignment_t configureAutomations() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Configure_Automations'));
        return this;
    }

    public PermissionSetAssignment_t executeAutomations() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Execute_Automations'));
        return this;
    }

    public PermissionSetAssignment_t configureSnapshots() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Configure_Snapshot'));
        return this;
    }

    public PermissionSetAssignment_t personaManagement() {
        permissionSet(PERMISSION_SET_BY_NAME.get('Persona_Management'));
        return this;
    }

    public PermissionSetAssignment_t permissionSet(Id permissionSet) {
        set(PermissionSetAssignment.PermissionSetId, permissionSet);
        return this;
    }

    public PermissionSetAssignment_t add(CustomPermission_t customPermission) {
        customPermission.setPermissionSetId(PERMISSION_SET_BY_NAME.get('Copado_User'));
        return this;
    }
}