@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class WebhookSettingsCtrl {

    @TestVisible
    private static final Datetime NOW = Datetime.now();

    @TestVisible
    private static final String USER_API_KEY = DeployAPI.getUserAPIKey();

    // PUBLIC

    @AuraEnabled
    public static List<ActionAPIKey> getActionKeys() {
        try {
            validateUserApiKey();

            List<ActionAPIKey> result = new List<ActionAPIKey>();

            List<Webhook_Settings__c> actionKeys = [
                SELECT Key__c, Action__c, Start_Date__c, End_Date__c, UserId__c
                FROM Webhook_Settings__c
                WHERE UserId__c = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
                ORDER BY End_Date__c DESC
            ];

            Map<Id, User> userById = new Map<Id, User>(getUsers(actionKeys));

            for (Webhook_Settings__c aKey : actionKeys) {
                result.add( new ActionAPIKey(aKey, userById.get(aKey.UserId__c)) );
            }

            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }


    @AuraEnabled
    public static void saveActionKey(String actionKeyData) {
        try {
            validateUserApiKey();
            
            ActionAPIKey actionKey = (ActionAPIKey) JSON.deserialize(actionKeyData, ActionAPIKey.class);

            if (actionKey.id == null) {
                createActionKey(actionKey);
            } else {
                updateActionKey(actionKey);
            }
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }


    @AuraEnabled
    public static void deleteActionKey(String actionKeyId) {
        try {
            delete new Webhook_Settings__c(Id = actionKeyId);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static void createActionKey(ActionAPIKey actionKey) {
        insert new Webhook_Settings__c(
            Name = (actionKey.userId + '_' + NOW).remove(':'),
            Key__c = generateKey(actionKey.userId),
            Action__c = actionKey.actions,
            Start_Date__c = NOW,
            End_Date__c = NOW.addDays(actionKey.expiresInDays),
            UserId__c = actionKey.userId
        );
    }


    private static void updateActionKey(ActionAPIKey actionKey) {
        String key = actionKey.isUserApiKeyChanged ? generateKey(actionKey.userId) : actionKey.key;

        update new Webhook_Settings__c(
            Id = actionKey.id,
            Key__c = key,
            Action__c = actionKey.actions,
            End_Date__c = NOW.addDays(actionKey.expiresInDays),
            UserId__c = actionKey.userId
        );
    }


    private static String generateKey(Id userId) {
        Blob partialKey = Blob.valueOf(userId + '' + NOW);
        String encryptedKey = EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', partialKey));

        return encryptedKey + USER_API_KEY;
    }


    private static List<User> getUsers(List<Webhook_Settings__c> actionKeys) {
        Set<Id> userIds = new Set<Id>();

        for (Webhook_Settings__c aKey : actionKeys) {
            userIds.add(aKey.UserId__c);
        }

        return new UsersSelector().byId(userIds);
    }


    private static void validateUserApiKey() {
        if(String.isBlank(USER_API_KEY)) {
            throw new ApplicationException(Label.API_KEY_MISSING);
        }
    }

    // INNER

    public class ActionAPIKey {
        @AuraEnabled
        public Id id;

        @AuraEnabled
        public String key;

        @AuraEnabled
        public String actions;

        @AuraEnabled
        public Date startDate;

        @AuraEnabled
        public Date endDate;

        @AuraEnabled
        public String userId;

        @AuraEnabled
        public Boolean isExpired = false;

        @AuraEnabled
        public Boolean isUserApiKeyChanged = false;

        @AuraEnabled
        public String username;

        @AuraEnabled
        public Integer expiresInDays;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public ActionAPIKey() {
        }

        public ActionAPIKey(Webhook_Settings__c actionKey, User usr) {
            this.id = actionKey.Id;
            this.key = actionKey.Key__c;
            this.actions = actionKey.Action__c;
            this.userId = actionKey.UserId__c;
            this.username = usr.Email;
            this.startDate = actionKey.Start_Date__c.date();
            this.endDate = actionKey.End_Date__c.date();
            this.expiresInDays = NOW.date().daysBetween(actionKey.End_Date__c.date());
            this.isExpired = isExpired();
            this.isUserApiKeyChanged = isUserApiKeyChanged();
        }

        private Boolean isExpired() {
            return NOW.date() > endDate;
        }

        private Boolean isUserApiKeyChanged() {
            return !key.endsWith(USER_API_KEY);
        }
    }
}