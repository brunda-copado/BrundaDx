import _checkUserPermissions from '@salesforce/apex/PersonaManagementServiceCtrl.checkUserPermissions';
import getDefaultPersonas from '@salesforce/apex/PersonaManagementServiceCtrl.getDefaultPersonas';
import createDefaultPersonaConfig from '@salesforce/apex/PersonaManagementServiceCtrl.createDefaultPersonaConfig';
import createDefaultPersonaRecord from '@salesforce/apex/PersonaManagementServiceCtrl.createDefaultPersonaRecord';
import _checkDefaultPersonaUpdates from '@salesforce/apex/PersonaManagementServiceCtrl.checkDefaultPersonaUpdates';
import _applyDefaultPersonaUpdates from '@salesforce/apex/PersonaManagementServiceCtrl.applyDefaultPersonaUpdates';
import _updatePersona from '@salesforce/apex/PersonaManagementServiceCtrl.updatePersona';
import _getPersonas from '@salesforce/apex/PersonaManagementServiceCtrl.getPersonas';
import _getPersonaDefinitions from '@salesforce/apex/PersonaManagementServiceCtrl.getPersonaDefinitions';
import createCopyPersonaConfig from '@salesforce/apex/PersonaManagementServiceCtrl.createCopyPersonaConfig';
import createCopyPersonaRecord from '@salesforce/apex/PersonaManagementServiceCtrl.createCopyPersonaRecord';
import _editPersonaDescription from '@salesforce/apex/PersonaManagementServiceCtrl.editPersonaDescription';
import _deletePersona from '@salesforce/apex/PersonaManagementServiceCtrl.deletePersona';
import _deletePersona2 from '@salesforce/apex/PersonaManagementServiceCtrl.deletePersona2';
import _deletePersona3 from '@salesforce/apex/PersonaManagementServiceCtrl.deletePersona3';
import _getUsers from '@salesforce/apex/PersonaManagementUserServiceCtrl.getUsers';
import _getUsersForPersona from '@salesforce/apex/PersonaManagementUserServiceCtrl.getUsersForPersona';
import _addUser from '@salesforce/apex/PersonaManagementUserServiceCtrl.addUser';
import _addUser2 from '@salesforce/apex/PersonaManagementUserServiceCtrl.addUser2';
import _addUser3 from '@salesforce/apex/PersonaManagementUserServiceCtrl.addUser3';
import _removeUser from '@salesforce/apex/PersonaManagementUserServiceCtrl.removeUser';
import _removeUser2 from '@salesforce/apex/PersonaManagementUserServiceCtrl.removeUser2';
import _removeUser3 from '@salesforce/apex/PersonaManagementUserServiceCtrl.removeUser3';
import _resetPassword from '@salesforce/apex/PersonaManagementUserServiceCtrl.resetPassword';
import _getPermissionSetGroups from '@salesforce/apex/PersonaManagementPermissionServiceCtrl.getPermissionSetGroups';
import _getPermissionsForPersona from '@salesforce/apex/PersonaManagementPermissionServiceCtrl.getPermissionsForPersona';
import _addPermissionSetGroup from '@salesforce/apex/PersonaManagementPermissionServiceCtrl.addPermissionSetGroup';
import _addPermissionSetGroup2 from '@salesforce/apex/PersonaManagementPermissionServiceCtrl.addPermissionSetGroup2';
import _removePermission from '@salesforce/apex/PersonaManagementPermissionServiceCtrl.removePermission';
import _removePermission2 from '@salesforce/apex/PersonaManagementPermissionServiceCtrl.removePermission2';
import _getLicenses from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.getLicenses';
import _getLicensesForPersona from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.getLicensesForPersona';
import _addPackageLicense from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.addPackageLicense';
import _addCopadoLicense from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.addCopadoLicense';
import _addPackageLicense2 from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.addPackageLicense2';
import _addCopadoLicense2 from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.addCopadoLicense2';
import _removePackageLicense from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.removePackageLicense';
import _removeCopadoLicense from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.removeCopadoLicense';
import _removePackageLicense2 from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.removePackageLicense2';
import _removeCopadoLicense2 from '@salesforce/apex/PersonaManagementLicenseServiceCtrl.removeCopadoLicense2';
import _getCredentials from '@salesforce/apex/PersonaManagementCredentialServiceCtrl.getCredentials';
import _getCredentialsForPersona from '@salesforce/apex/PersonaManagementCredentialServiceCtrl.getCredentialsForPersona';
import _shareCredentials from '@salesforce/apex/PersonaManagementCredentialServiceCtrl.shareCredentials';
import _removeCredential from '@salesforce/apex/PersonaManagementCredentialServiceCtrl.removeCredential';
import _changeCredentialAccessLevel from '@salesforce/apex/PersonaManagementCredentialServiceCtrl.changeCredentialAccessLevel';

import { namespace } from 'c/copadocoreUtils';

// INIT

export const checkUserPermissions = async () => {
    const userHasPermission = await _checkUserPermissions();
    return userHasPermission;
};

export const createDefaultPersonas = async (defaultPersonas) => {
    if (defaultPersonas.length === 0) {
        defaultPersonas = await getDefaultPersonas();
    }
    const personaPromises = defaultPersonas.map((defaultPersona) => {
        return createDefaultPersonaConfig({ personaName: defaultPersona.MasterLabel }).then((personaConfig) => {
            return createDefaultPersonaRecord({
                personaName: defaultPersona.MasterLabel,
                description: defaultPersona[namespace + 'Description__c'],
                personaConfig: JSON.stringify(personaConfig)
            });
        });
    });

    await Promise.all(personaPromises);
};

export const checkDefaultPersonaUpdates = async () => {
    const personasWithUpdates = await _checkDefaultPersonaUpdates();
    return personasWithUpdates;
};

export const updatePersona = async (personaId, description, personaConfig) => {
    await _updatePersona(personaId, description, personaConfig);
};

export const applyDefaultPersonaUpdates = async (personaNames) => {
    const personaPromises = personaNames.map((personaName) => {
        return _applyDefaultPersonaUpdates({ personaName: personaName }).then((result) => {
            if (result.defaultPersonaToCreate) {
                return createDefaultPersonas([result.defaultPersonaToCreate]);
            }
            return updatePersona({
                personaId: result.updatedPersonaId,
                description: result.updatedPersonaDescription,
                personaConfig: result.updatedPersonaConfigJson
            });
        });
    });

    const newDefaultPersonas = await Promise.all(personaPromises);
    return newDefaultPersonas.filter((persona) => persona != null);
};

// SIDEBAR

export const getPersonas = async () => {
    const personaDefinitions = await _getPersonas();
    return personaDefinitions;
};

export const getPersonaDefinitions = async () => {
    const personaDefinitions = await _getPersonaDefinitions();
    return personaDefinitions;
};

export const createPersona = async (personaInput) => {
    const personaConfigResult = await createCopyPersonaConfig({ name: personaInput.name, copyFrom: personaInput.copyFrom });
    await createCopyPersonaRecord({
        name: personaInput.name,
        description: personaInput.description,
        personaConfig: JSON.stringify(personaConfigResult)
    });
};

export const editPersonaDescription = async (personaId, description) => {
    await _editPersonaDescription(personaId, description);
};

export const deletePersona = async (personaId) => {
    await _deletePersona(personaId);
    await _deletePersona2(personaId);
    await _deletePersona3(personaId);
};

// USERS TAB

export const getUsers = async () => {
    const users = await _getUsers();
    return users;
};

export const getUsersForPersona = async (personaId) => {
    const users = await _getUsersForPersona(personaId);
    return users;
};

export const addUser = async (personaId, userIds) => {
    await _addUser(personaId, userIds);
    await _addUser2(personaId, userIds);
    await _addUser3(personaId, userIds);
};

export const removeUser = async (personaId, userIds) => {
    await _removeUser(personaId, userIds);
    await _removeUser2(personaId, userIds);
    await _removeUser3(personaId, userIds);
};

export const resetPassword = async (userId) => {
    await _resetPassword(userId);
};

export const createUser = () => {
    window.open('/005/e?isUserEntityOverride=1', '_blank');
};

// PERMISSIONS TAB

export const getPermissionSetGroups = async () => {
    const permissionSetGroups = await _getPermissionSetGroups();
    return permissionSetGroups;
};

export const getPermissionsForPersona = async personaId => {
    const permissionSetGroups = await _getPermissionsForPersona(personaId);
    return permissionSetGroups;
};

export const addPermissionSetGroup = async (personaId, permissionSetGroups) => {
    await _addPermissionSetGroup(personaId, permissionSetGroups);
    await _addPermissionSetGroup2(personaId, permissionSetGroups);
};

export const removePermission = async (personaId, permissions) => {
    await _removePermission(personaId, permissions);
    await _removePermission2(personaId, permissions);
};

// LICENSE TAB

export const getLicenses = async () => {
    const licenses = await _getLicenses();
    return licenses;
};

export const getLicensesForPersona = async (personaId) => {
    const licenses = await _getLicensesForPersona(personaId);
    return licenses;
};

export const addPackageLicense = async (personaId, licenses) => {
    await _addPackageLicense(personaId, licenses);
    await _addPackageLicense2(personaId, licenses);
};

export const addLicense = async (personaId, licenses) => {
    await _addCopadoLicense(personaId, licenses);
    await _addCopadoLicense2(personaId, licenses);
};

export const removePackageLicense = async (personaId, licenses) => {
    await _removePackageLicense(personaId, licenses);
    await _removePackageLicense2(personaId, licenses);
};

export const removeLicense = async (personaId, licenses) => {
    await _removeCopadoLicense(personaId, licenses);
    await _removeCopadoLicense2(personaId, licenses);
};

// CREDENTIALS TAB

export const getCredentials = async () => {
    const credentials = await _getCredentials();
    return credentials;
};

export const getCredentialsForPersona = async (personaId) => {
    const credentials = await _getCredentialsForPersona(personaId);
    return credentials;
};

export const shareCredentials = async (personaId, credentialIds) => {
    await _shareCredentials(personaId, credentialIds);
};

export const removeCredential = async (personaId, credentialIds) => {
    await _removeCredential(personaId, credentialIds);
};

export const changeCredentialAccessLevel = async (personaId, credentialId, accessLevel) => {
    await _changeCredentialAccessLevel(personaId, credentialId, accessLevel);
};