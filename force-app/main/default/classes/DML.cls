@SuppressWarnings('PMD.CyclomaticComplexity,PMD.ExcessivePublicCount')
public with sharing class DML {
    private static Boolean allOrNone = true;

    public static void allOrNone(Boolean allOrNoneValue) {
        allOrNone = allOrNoneValue;
    }


    public static void safeInsert(SObject record, String errorMessage) {
        safeInsert(new List<SObject>{ record }, errorMessage);
    }


    public static void safeInsert(List<SObject> records, String errorMessage) {
        try {
            List<Database.SaveResult> saveResults = Database.insert(records, allOrNone, AccessLevel.USER_MODE);
            handleSaveResults(saveResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'CREATABLE'));
        }
    }


    public static void insertAsSystem(SObject record, String errorMessage) {
        insertAsSystem(new List<SObject>{ record }, errorMessage);
    }


    public static void insertAsSystem(List<SObject> records, String errorMessage) {
        try {
            List<Database.SaveResult> saveResults = Database.insert(records, allOrNone);
            handleSaveResults(saveResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'CREATABLE'));
        }
    }


    public static void safeUpdate(SObject record, String errorMessage) {
        safeUpdate(new List<SObject>{ record }, errorMessage);
    }


    public static void safeUpdate(List<SObject> records, String errorMessage) {
        try {
            List<Database.SaveResult> updateResults = Database.update(records, allOrNone, AccessLevel.USER_MODE);
            handleSaveResults(updateResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'UPDATABLE'));
        }
    }


    public static void updateAsSystem(SObject record, String errorMessage) {
        updateAsSystem(new List<SObject>{ record }, errorMessage);
    }


    public static void updateAsSystem(List<SObject> records, String errorMessage) {
        try {
            List<Database.SaveResult> updateResults = Database.update(records, allOrNone);
            handleSaveResults(updateResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'UPDATABLE'));
        }
    }


    public static void safeUpsert(SObject record, String errorMessage) {
        safeUpsert(new List<SObject>{ record }, errorMessage);
    }


    public static void safeUpsert(SObject record, Schema.SObjectField externalIdField, String errorMessage) {
        safeUpsert(new List<SObject>{ record }, externalIdField, errorMessage);
    }


    public static void upsertAsSystem(SObject record, String errorMessage) {
        upsertAsSystem(new List<SObject>{ record }, errorMessage);
    }


    public static void upsertAsSystem(SObject record, Schema.SObjectField externalIdField, String errorMessage) {
        upsertAsSystem(new List<SObject>{ record }, externalIdField, errorMessage);
    }


    public static void safeUpsert(List<SObject> records, String errorMessage) {
        try {
            List<Database.UpsertResult> upsertResults = Database.upsert(records, allOrNone, AccessLevel.USER_MODE);
            handleUpsertResults(upsertResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'UPSERTABLE'));
        }
    }


    public static void safeUpsert(List<SObject> records, Schema.SObjectField externalIdField, String errorMessage) {
        try {
            List<Database.UpsertResult> upsertResults = Database.upsert(records, externalIdField, allOrNone, AccessLevel.USER_MODE);
            handleUpsertResults(upsertResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'UPSERTABLE'));
        }
    }


    public static void upsertAsSystem(List<SObject> records, String errorMessage) {
        try {
            List<Database.UpsertResult> upsertResults = Database.upsert(records, allOrNone);
            handleUpsertResults(upsertResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'UPSERTABLE'));
        }
    }


    public static void upsertAsSystem(List<SObject> records, Schema.SObjectField externalIdField, String errorMessage) {
        try {
            List<Database.UpsertResult> upsertResults = Database.upsert(records, externalIdField, allOrNone);
            handleUpsertResults(upsertResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'UPSERTABLE'));
        }
    }


    public static void safeDelete(SObject record, String errorMessage) {
        safeDelete(new List<SObject>{ record }, errorMessage);
    }


    public static void safeDelete(List<SObject> records, String errorMessage) {
        try {
            List<Database.DeleteResult> deleteResults = Database.delete(records, allOrNone, AccessLevel.USER_MODE);
            handleDeleteResults(deleteResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'DELETABLE'));
        }
    }


    public static void deleteAsSystem(SObject record, String errorMessage) {
        deleteAsSystem(new List<SObject>{ record }, errorMessage);
    }


    public static void deleteAsSystem(List<SObject> records, String errorMessage) {
        try {
            List<Database.DeleteResult> deleteResults = Database.delete(records, allOrNone);
            handleDeleteResults(deleteResults);
        } catch(Exception ex) {
            throw new ApplicationException(format(ex, errorMessage, records[0], 'DELETABLE'));
        }
    }


    private static void handleSaveResults(List<Database.SaveResult> saveResults) {
        List<String> errorMessages = new List<String>();
        for (Database.SaveResult saveResult : saveResults) {
            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    errorMessages.add(error.getMessage());
                }
            }
        }
        if (!errorMessages.isEmpty()) {
            throw new ApplicationException(String.join(errorMessages, ', '));
        }
    }


    private static void handleDeleteResults(List<Database.DeleteResult> deleteResults) {
        List<String> errorMessages = new List<String>();
        for (Database.DeleteResult deleteResult : deleteResults) {
            if (!deleteResult.isSuccess()) {
                for (Database.Error error : deleteResult.getErrors()) {
                    errorMessages.add(error.getMessage());
                }
            }
        }
        if (!errorMessages.isEmpty()) {
            throw new ApplicationException(String.join(errorMessages, ', '));
        }
    }


    private static void handleUpsertResults(List<Database.UpsertResult> upsertResults) {
        List<String> errorMessages = new List<String>();
        for (Database.UpsertResult upsertResult : upsertResults) {
            if (!upsertResult.isSuccess()) {
                for (Database.Error error : upsertResult.getErrors()) {
                    errorMessages.add(error.getMessage());
                }
            }
        }
        if (!errorMessages.isEmpty()) {
            throw new ApplicationException(String.join(errorMessages, ', '));
        }
    }


    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static String format(Exception ex, String errorMessage, SObject record, String actionType) {
        return String.format(Label.DML_Generic_Error, new List<String> {
                    errorMessage,
                    reducedErrorMessage(ex, record),
                    String.valueOf(record.getSObjectType()),
                    UserInfo.getUserId(),
                    String.valueOf(actionType),
                    record?.Id
                });
    }


    private static String reducedErrorMessage(Exception ex, SObject record) {
        if (ex.getTypeName() == 'System.DmlException' && ex.getMessage().contains('fields being inaccessible')) {
            return String.format(Label.DML_Access_Error, new List<String> {record.getSObjectType().getDescribe().getName(), String.join(ex.getDmlFieldNames(0), ', ')});
        }

        return ex.getMessage();
    }
}