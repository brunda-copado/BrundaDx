@SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.ExcessivePublicCount, PMD.CognitiveComplexity')
public inherited sharing class Persona implements CopadoDomain {
    /************ CREATE ***********************/

    public static CreateConfigResult createConfig(CreateConfigRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            return PersonaServiceImpl.createConfig(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    public static CreateRecordResult createRecord(CreateRecordRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            return PersonaServiceImpl.createRecord(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    public static void deletePersona(DeletePersonaRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            PersonaServiceImpl.deletePersona(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    public static void deletePersona2(DeletePersonaRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            PersonaServiceImpl.deletePersona2(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    public static void deletePersona3(DeletePersonaRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            PersonaServiceImpl.deletePersona3(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class CreateConfigRequest implements CopadoServiceRequest {
        public String personaName;
        public String copyFrom;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class CreateConfigResult implements CopadoServiceResult {
        public PersonaDefinitionConfig personaConfig;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class CreateRecordRequest implements CopadoServiceRequest {
        public String personaName;
        public String description;
        public PersonaDefinitionConfig personaConfig;
        public Boolean isStandard;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class CreateRecordResult implements CopadoServiceResult {
        public Persona_Definition__c persona;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class DeletePersonaRequest implements CopadoServiceRequest {
        public Id personaId;
    }

    /************ CREATE ***********************/

    /************ LICENSE ***********************/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static LicenseService LicenseService {
        get {
            if (LicenseService == null) {
                LicenseService = new LicenseService();
            }
            return LicenseService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Persona Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public inherited sharing class LicenseService implements CopadoService {

        public void addPackageLicense(AddLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                AddLicenseServiceImpl.addPackageLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void addCopadoLicense(AddLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                AddLicenseServiceImpl.addCopadoLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void add2PackageLicense(AddLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                AddLicenseServiceImpl.add2PackageLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void add2CopadoLicense(AddLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                AddLicenseServiceImpl.add2CopadoLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void removePackageLicense(RemoveLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                RemoveLicenseServiceImpl.removePackageLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void removeCopadoLicense(RemoveLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                RemoveLicenseServiceImpl.removeCopadoLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove2PackageLicense(RemoveLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                RemoveLicenseServiceImpl.remove2PackageLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove2CopadoLicense(RemoveLicenseRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                RemoveLicenseServiceImpl.remove2CopadoLicense(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class AddLicenseRequest implements CopadoServiceRequest {
        public Id personaId; // Id of the Persona
        public List<String> licenses; // List of License Names that you want to add
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class RemoveLicenseRequest implements CopadoServiceRequest {
        public Id personaId; // Id of the Persona
        public List<String> licenses; //List of License Names that you want to remove
    }

    /************ LICENSE ***********************/

    /************ PERMISSION *********************/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static PermissionService PermissionService {
        get {
            if (PermissionService == null) {
                PermissionService = new PermissionService();
            }
            return PermissionService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Persona Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public inherited sharing class PermissionService implements CopadoService {
        public void add(AddPermissionRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                AddPermissionServiceImpl.add(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void add2(AddPermissionRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                AddPermissionServiceImpl.add2(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove(RemovePermissionRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                RemovePermissionServiceImpl.remove(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove2(RemovePermissionRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                RemovePermissionServiceImpl.remove2(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class AddPermissionRequest implements CopadoServiceRequest {
        public Id personaId; // Id of the persona
        public List<String> permissionSetGroups; // List of permission set group Names
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class RemovePermissionRequest implements CopadoServiceRequest {
        public Id personaId; // Id of the persona
        public List<Permission> permissions; // List of permission to remove
    }

    @JsonAccess(serializable='always' deserializable='always')
    public with sharing class Permission {
        public String name;
        public String type;
    }

    /************ PERMISSION ***********************/

    /************ CREDENTIAL ***********************/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static CredentialService CredentialService {
        get {
            if (CredentialService == null) {
                CredentialService = new CredentialService();
            }
            return CredentialService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Persona Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public inherited sharing class CredentialService implements CopadoService {
        public void share(ShareCredentialRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaCredentialServiceImpl.share(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove(RemoveCredentialRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaCredentialServiceImpl.remove(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void updateAccessLevel(UpdateAccessLevelRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaCredentialServiceImpl.updateAccessLevel(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class ShareCredentialRequest implements CopadoServiceRequest {
        public Id personaId;
        public List<Id> credentialIds;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class RemoveCredentialRequest implements CopadoServiceRequest {
        public Id personaId;
        public List<Id> credentialIds;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class UpdateAccessLevelRequest implements CopadoServiceRequest {
        public Id personaId;
        public List<Id> credentialIds;
        public String accessLevel; // Valid values: Read, Edit
    }

    /************ CREDENTIAL ***********************/

    /************ USER ***********************/

    //SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static UserService UserService {
        get {
            if (UserService == null) {
                UserService = new UserService();
            }
            return UserService;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Persona Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public inherited sharing class UserService implements CopadoService {
        public void add(AddUserRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaUserServiceImpl.add(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void add2(AddUserRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaUserServiceImpl.add2(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void add3(AddUserRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaUserServiceImpl.add3(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove(RemoveUserRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaUserServiceImpl.remove(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove2(RemoveUserRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaUserServiceImpl.remove2(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void remove3(RemoveUserRequest request) {
            Savepoint sp = Database.setSavepoint();
            try {
                PersonaUserServiceImpl.remove3(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class AddUserRequest implements CopadoServiceRequest {
        public Id personaId;
        public List<Id> userIds;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class RemoveUserRequest implements CopadoServiceRequest {
        public Id personaId;
        public List<Id> userIds;
    }

    /************ USER ***********************/
}