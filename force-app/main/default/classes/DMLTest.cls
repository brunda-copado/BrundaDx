@SuppressWarnings('PMD.CyclomaticComplexity')
@IsTest
private class DMLTest {
    private final static String OBJECT_NAME = String.valueOf(System_Property__c.getSobjectType());
    private final static String FIELD_NAME = String.valueOf(System_Property__c.Is_Sensitive__c.getDescribe().getName());

    @TestSetup
    private static void setupData() {
        Id readOnlyProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;

        List<User> users = new List<User>{
            user('restricted1@testuser.com', 'rtestus1', readOnlyProfileId),
            user('restricted2@testuser.com', 'rtestus2', readOnlyProfileId)
        };
        insert users;

        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_Functions'];

        ObjectPermissions systemPropertiesObjectPermissions = [
            SELECT Id
            FROM ObjectPermissions
            WHERE SObjectType = :OBJECT_NAME AND ParentId = :permissionSet.Id
        ];
        systemPropertiesObjectPermissions.PermissionsViewAllRecords = true;
        systemPropertiesObjectPermissions.PermissionsModifyAllRecords = true;
        update systemPropertiesObjectPermissions;

        List<FieldPermissions> fieldPermissions = [
            SELECT Id, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE SObjectType = :OBJECT_NAME AND ParentId = :permissionSet.Id
        ];

        for (FieldPermissions fieldPermission : fieldPermissions) {
            if (fieldPermission.Field.contains(FIELD_NAME)) {
                fieldPermission.PermissionsRead = false;
                fieldPermission.PermissionsEdit = false;
            }
        }
        update fieldPermissions;

        insert new PermissionSetAssignment(AssigneeId = users[0].Id, PermissionSetId = permissionSet.Id);
    }

    @IsTest
    private static void dmlWithEmptyList() {
        // Setup
        Exception expectedException = null;

        // Exercise
        System.runAs(getUserWithPermissions()) {
            try {
                DML.safeInsert(new List<System_Property__c>(), 'Test Error');
            } catch (Exception ex) {
                expectedException = ex;
            }
        }

        // Verify
        Assert.isNull(expectedException, 'Exception should not been thrown');
    }

    @IsTest
    private static void insertRecordAsUserWithPermission() {
        // Setup
        Exception expectedException = null;
        User userWithPermissions = getUserWithPermissions();
        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id);

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeInsert(newRecord, 'Test Error');
            } catch (Exception ex) {
                expectedException = ex;
            }
        }

        // Verify
        Assert.isNull(expectedException, 'Exception should not been thrown');
        List<System_Property__c> results = [SELECT Id FROM System_Property__c];
        Assert.areEqual(1, results.size(), 'Number of records created does not match');
        Assert.areEqual(newRecord.Id, results[0].Id, 'Record Id does not match');
    }

    @IsTest
    private static void insertRecordsAsUserWithoutPermission() {
        // Setup
        Exception expectedEception = null;
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id)
        };

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeInsert(newRecords, 'Test Error');
            } catch (Exception ex) {
                expectedEception = ex;
            }
        }

        // Verify
        Assert.isNull(expectedEception, 'Exception should not been thrown');

        List<System_Property__c> results = [SELECT Id FROM System_Property__c ORDER BY API_Name__c ASC];
        Assert.areEqual(2, results.size(), 'Number of records created does not match');
        Assert.areEqual(newRecords[0].Id, results[0].Id, 'Record Id does not match');
        Assert.areEqual(newRecords[1].Id, results[1].Id, 'Record Id does not match');
    }

    @IsTest
    private static void insertRecordAsUserWithoutFieldPermission() {
        // Setup
        String exceptionMessage = null;
        User userWithPermissions = getUserWithPermissions();

        System_Property__c newRecord = new System_Property__c(
            API_Name__c = 'Test',
            User__c = userWithPermissions.Id,
            Value__c = 'Test',
            Is_Sensitive__c = true
        );

        String errorMessage = 'Test Error';

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeInsert(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        String expectedError = String.format(Label.DML_Access_Error, new List<String>{ OBJECT_NAME, FIELD_NAME });
        String expectedFullError = String.format(
            Label.DML_Generic_Error,
            new List<String>{
                errorMessage,
                expectedError,
                String.valueOf(newRecord.getSObjectType()),
                userWithPermissions.Id,
                String.valueOf(AccessType.CREATABLE),
                null
            }
        );
        Assert.areEqual(expectedFullError, exceptionMessage, 'Error message does not match');
    }

    @IsTest
    private static void insertRecordAsUserWithoutFieldPermissionsWithAllOrNoneSetToFalse() {
        // Setup
        String exceptionMessage = null;
        User userWithPermissions = getUserWithPermissions();

        System_Property__c newRecord = new System_Property__c(
            API_Name__c = 'Test',
            User__c = userWithPermissions.Id,
            Value__c = 'Test',
            Is_Sensitive__c = true
        );

        String errorMessage = 'Test Error';

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.allOrNone(false);
                DML.safeInsert(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        String expectedError = String.format(Label.DML_Access_Error, new List<String>{ OBJECT_NAME, FIELD_NAME });
        String expectedFullError = String.format(
            Label.DML_Generic_Error,
            new List<String>{
                errorMessage,
                expectedError,
                String.valueOf(newRecord.getSObjectType()),
                userWithPermissions.Id,
                String.valueOf(AccessType.CREATABLE),
                null
            }
        );
        Assert.areEqual(expectedFullError, exceptionMessage, 'Error message does not match');
    }

    @IsTest
    private static void insertRecordsAsUserWithoutFieldPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true),
            new System_Property__c(API_Name__c = 'Test2', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true)
        };

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeInsert(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        String expectedError = String.format(Label.DML_Access_Error, new List<String>{ OBJECT_NAME, FIELD_NAME });
        String expectedFullError = String.format(
            Label.DML_Generic_Error,
            new List<String>{
                errorMessage,
                expectedError,
                String.valueOf(newRecords[0].getSObjectType()),
                userWithPermissions.Id,
                String.valueOf(AccessType.CREATABLE),
                null
            }
        );
        Assert.areEqual(expectedFullError, exceptionMessage, 'Error message does not match');
    }

    @IsTest
    private static void insertRecordAsUserWithoutObjectPermission() {
        // Setup
        User userWithoutPermissions = getUserWithoutPermissions();

        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id);

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.safeInsert(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isTrue(exceptionMessage.contains(errorMessage), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Object: ' + newRecord.getSObjectType()), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('UserId: ' + userWithoutPermissions.Id), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Action: ' + AccessType.CREATABLE), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Id: ' + null), exceptionMessage);
    }

    @IsTest
    private static void insertRecordsAsUserWithoutObjectPermission() {
        // Setup
        User userWithoutPermissions = getUserWithoutPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id)
        };

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.safeInsert(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isTrue(exceptionMessage.contains(errorMessage), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Object: ' + newRecords[0].getSObjectType()), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('UserId: ' + userWithoutPermissions.Id), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Action: ' + AccessType.CREATABLE), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Id: ' + null), exceptionMessage);
    }

    @IsTest
    private static void insertRecordsAsSystemWithoutFieldPermission() {
        // Setup
        String exceptionMessage = null;
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true),
            new System_Property__c(API_Name__c = 'Test2', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true)
        };

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.insertAsSystem(newRecords, 'Test Error');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Error message does not match');
        Assert.areEqual(2, [SELECT COUNT() FROM System_Property__c], '2 System Property Record not created');
    }

    @IsTest
    private static void insertRecordsAsSystemWithoutObjectPermission() {
        // Setup
        String exceptionMessage = null;
        SystemProperties.disableCRUDSecurity = true;
        User userWithoutPermissions = getUserWithoutPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id)
        };

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.insertAsSystem(newRecords, 'Test Error');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Error message does not match');
        Assert.areEqual(2, [SELECT COUNT() FROM System_Property__c], '2 System Property Records not created');
    }

    @IsTest
    private static void updateRecordAsUserWithPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id);
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                newRecord.API_Name__c = 'Test1';
                DML.safeUpdate(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Exception should not been thrown');
        List<System_Property__c> results = [SELECT API_Name__c FROM System_Property__c];
        Assert.areEqual(1, results.size(), 'Number of records created does not match');
        Assert.areEqual('Test1', results[0].API_Name__c, 'Record API_Name__c does not match');
    }

    @IsTest
    private static void updateRecordsAsUserWithPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id)
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                newRecords[0].API_Name__c = 'Test01';
                newRecords[1].API_Name__c = 'Test02';
                DML.safeUpdate(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Exception should not been thrown');
        List<System_Property__c> results = [SELECT API_Name__c FROM System_Property__c ORDER BY API_Name__c ASC];
        Assert.areEqual(2, results.size(), 'Number of records created does not match');
        Assert.areEqual('Test01', results[0].API_Name__c, 'Record API_Name__c does not match');
        Assert.areEqual('Test02', results[1].API_Name__c, 'Record API_Name__c does not match');
    }

    @IsTest
    private static void updateRecordAsUserWithoutFieldPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        System_Property__c newRecord = new System_Property__c(
            API_Name__c = 'Test',
            User__c = userWithPermissions.Id,
            Value__c = 'Test',
            Is_Sensitive__c = true
        );
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeUpdate(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        String expectedError = String.format(Label.DML_Access_Error, new List<String>{ OBJECT_NAME, FIELD_NAME });
        String expectedFullError = String.format(
            Label.DML_Generic_Error,
            new List<String>{
                errorMessage,
                expectedError,
                String.valueOf(newRecord.getSObjectType()),
                userWithPermissions.Id,
                String.valueOf(AccessType.UPDATABLE),
                newRecord.Id
            }
        );
        Assert.areEqual(expectedFullError, exceptionMessage, 'Error message does not match');
    }

    @IsTest
    private static void updateRecordsAsUserWithoutFieldPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true),
            new System_Property__c(API_Name__c = 'Test2', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true)
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeUpdate(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        String expectedError = String.format(Label.DML_Access_Error, new List<String>{ OBJECT_NAME, FIELD_NAME });
        String expectedFullError = String.format(
            Label.DML_Generic_Error,
            new List<String>{
                errorMessage,
                expectedError,
                String.valueOf(newRecords[0].getSObjectType()),
                userWithPermissions.Id,
                String.valueOf(AccessType.UPDATABLE),
                newRecords[0].Id
            }
        );
        Assert.areEqual(expectedFullError, exceptionMessage, 'Error message does not match');
    }

    @IsTest
    private static void updateRecordAsUserWithoutObjectPermission() {
        // Setup
        User userWithoutPermissions = getUserWithoutPermissions();

        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id);
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.safeUpdate(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isTrue(exceptionMessage.contains(errorMessage), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Object: ' + newRecord.getSObjectType()), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('UserId: ' + userWithoutPermissions.Id), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Action: ' + AccessType.UPDATABLE), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Id: ' + newRecord.Id), exceptionMessage);
    }

    @IsTest
    private static void updateRecordsAsUserWithoutObjectPermission() {
        // Setup
        User userWithoutPermissions = getUserWithoutPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id)
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.safeUpdate(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isTrue(exceptionMessage.contains(errorMessage), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Object: ' + newRecords[0].getSObjectType()), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('UserId: ' + userWithoutPermissions.Id), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Action: ' + AccessType.UPDATABLE), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Id: ' + newRecords[0].Id), exceptionMessage);
    }

    @IsTest
    private static void upsertRecordAsUserWithPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id);
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                newRecord.API_Name__c = 'Test1';
                DML.safeUpsert(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Exception should not been thrown');
        List<System_Property__c> results = [SELECT API_Name__c FROM System_Property__c];
        Assert.areEqual(1, results.size(), 'Number of records created does not match');
        Assert.areEqual('Test1', results[0].API_Name__c, 'Record API_Name__c does not match');
    }

    @IsTest
    private static void upsertRecordsAsUserWithPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id)
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                newRecords[0].API_Name__c = 'Test01';
                newRecords[1].API_Name__c = 'Test02';
                DML.safeUpsert(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Exception should not been thrown');
        List<System_Property__c> results = [SELECT API_Name__c FROM System_Property__c ORDER BY API_Name__c ASC];
        Assert.areEqual(2, results.size(), 'Number of records created does not match');
        Assert.areEqual('Test01', results[0].API_Name__c, 'Record API_Name__c does not match');
        Assert.areEqual('Test02', results[1].API_Name__c, 'Record API_Name__c does not match');
    }

    @IsTest
    private static void upsertRecordAsUserWithoutFieldPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        System_Property__c newRecord = new System_Property__c(
            API_Name__c = 'Test',
            User__c = userWithPermissions.Id,
            Value__c = 'Test',
            Is_Sensitive__c = true
        );
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeUpsert(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        String expectedError = String.format(Label.DML_Access_Error, new List<String>{ OBJECT_NAME, FIELD_NAME });
        String expectedFullError = String.format(
            Label.DML_Generic_Error,
            new List<String>{
                errorMessage,
                expectedError,
                String.valueOf(newRecord.getSObjectType()),
                userWithPermissions.Id,
                String.valueOf(AccessType.UPSERTABLE),
                newRecord.Id
            }
        );
        Assert.areEqual(expectedFullError, exceptionMessage, 'Error message does not match');
    }

    @IsTest
    private static void upsertRecordsAsUserWithoutFieldPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true),
            new System_Property__c(API_Name__c = 'Test2', User__c = userWithPermissions.Id, Value__c = 'Test', Is_Sensitive__c = true)
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeUpsert(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        String expectedError = String.format(Label.DML_Access_Error, new List<String>{ OBJECT_NAME, FIELD_NAME });
        String expectedFullError = String.format(
            Label.DML_Generic_Error,
            new List<String>{
                errorMessage,
                expectedError,
                String.valueOf(newRecords[0].getSObjectType()),
                userWithPermissions.Id,
                String.valueOf(AccessType.UPSERTABLE),
                newRecords[0].Id
            }
        );
        Assert.areEqual(expectedFullError, exceptionMessage, 'Error message does not match');
    }

    @IsTest
    private static void upsertRecordAsUserWithoutObjectPermissions() {
        // Setup
        User userWithoutPermissions = getUserWithoutPermissions();

        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id);
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.safeUpsert(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isTrue(exceptionMessage.contains(errorMessage), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Object: ' + newRecord.getSObjectType()), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('UserId: ' + userWithoutPermissions.Id), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Action: ' + AccessType.UPSERTABLE), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Id: ' + newRecord.Id), exceptionMessage);
    }

    @IsTest
    private static void upsertRecordsAsUserWithoutObjectPermission() {
        // Setup
        User userWithoutPermissions = getUserWithoutPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id)
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.safeUpsert(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isTrue(exceptionMessage.contains(errorMessage), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Object: ' + newRecords[0].getSObjectType()), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('UserId: ' + userWithoutPermissions.Id), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Action: ' + AccessType.UPSERTABLE), exceptionMessage);
        Assert.isTrue(exceptionMessage.contains('Id: ' + newRecords[0].Id), exceptionMessage);
    }

    @IsTest
    private static void upsertRecordAsUserWithPermissionAndExternalId() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id);
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                newRecord.API_Name__c = 'Test1';
                DML.safeUpsert(newRecord, System_Property__c.Id, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Exception should not been thrown');
        List<System_Property__c> results = [SELECT API_Name__c FROM System_Property__c];
        Assert.areEqual(1, results.size(), 'Number of records created does not match');
        Assert.areEqual('Test1', results[0].API_Name__c, 'Record API_Name__c does not match');
    }

    @IsTest
    private static void upsertRecordsAsUserWithPermissionAndExternalId() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', User__c = userWithPermissions.Id, Value__c = 'Value1'),
            new System_Property__c(API_Name__c = 'Test2', User__c = userWithPermissions.Id, Value__c = 'Value2')
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                newRecords[0].API_Name__c = 'Test01';
                newRecords[1].API_Name__c = 'Test02';
                DML.safeUpsert(newRecords, System_Property__c.Id, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Exception should not been thrown');
        List<System_Property__c> results = [SELECT API_Name__c FROM System_Property__c ORDER BY API_Name__c ASC];
        Assert.areEqual(2, results.size(), 'Number of records created does not match');
        Assert.areEqual('Test01', results[0].API_Name__c, 'Record API_Name__c does not match');
        Assert.areEqual('Test02', results[1].API_Name__c, 'Record API_Name__c does not match');
    }

    @IsTest
    private static void deleteRecordsAsUserWithPermission() {
        // Setup
        User userWithPermissions = getUserWithPermissions();

        List<System_Property__c> newRecords = new List<System_Property__c>{
            new System_Property__c(API_Name__c = 'Test1', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id),
            new System_Property__c(API_Name__c = 'Test2', Value__c = 'USER-PROPERTY', User__c = userWithPermissions.Id)
        };
        insert newRecords;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithPermissions) {
            try {
                DML.safeDelete(newRecords, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        Assert.isNull(exceptionMessage, 'Exception should not been thrown');
        Assert.areEqual(0, [SELECT COUNT() FROM System_Property__c], 'Number of records deleted does not match');
    }

    @IsTest
    private static void deleteRecordAsUserWithoutObjectPermissions() {
        // Setup
        User userWithoutPermissions = getUserWithoutPermissions();

        System_Property__c newRecord = new System_Property__c(API_Name__c = 'Test', Value__c = 'USER-PROPERTY', User__c = userWithoutPermissions.Id);
        insert newRecord;

        String errorMessage = 'Test Error';
        String exceptionMessage = null;

        // Exercise
        System.runAs(userWithoutPermissions) {
            try {
                DML.safeDelete(newRecord, errorMessage);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
        }

        // Verify
        System.assert(exceptionMessage.contains(errorMessage), exceptionMessage);
        System.assert(exceptionMessage.contains('Object: ' + newRecord.getSObjectType()), exceptionMessage);
        System.assert(exceptionMessage.contains('UserId: ' + userWithoutPermissions.Id), exceptionMessage);
        System.assert(exceptionMessage.contains('Action: DELETABLE'), exceptionMessage);
        System.assert(exceptionMessage.contains('Id: ' + newRecord.Id), exceptionMessage);
    }

    // HELPER

    private static User getUserWithPermissions() {
        return [SELECT Id FROM User WHERE Username = 'restricted1@testuser.com' LIMIT 1];
    }

    private static User getUserWithoutPermissions() {
        return [SELECT Id FROM User WHERE Username = 'restricted2@testuser.com' LIMIT 1];
    }

    private static User user(String userName, String alias, Id profileId) {
        return new User(
            Username = userName,
            Email = userName,
            firstName = 'testx',
            lastName = 'userx',
            Alias = alias,
            emailencodingkey = 'UTF-8',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            profileId = profileId
        );
    }
}