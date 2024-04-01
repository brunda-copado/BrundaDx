@SuppressWarnings('PMD.AvoidGlobalModifier')
// AvoidGlobalModifier: As we want to expose the services as global, thus the modifier

global inherited sharing class CopadoNotifications implements CopadoDomain {
    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Notfications Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static void send(SendRequest request) {
        // Note: not setting savepoint as this service is not writing to database
        try {
            SendNotificationsImpl.execute(request);
        } catch (Exception e) {
            throw new ApplicationException(e.getMessage());
        }
    }

    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Notfications Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static SubscribeResult subscribe(SubscribeRequest request) {
        Savepoint sp = Database.setSavepoint();

        try {
            return SubscribeNotificationsImpl.execute(request);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the Notfications Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this method must contain an architect approval.
    */
    global static SubscribeResult unsubscribe(Id subscriptionId) {
        Savepoint sp = Database.setSavepoint();

        try {
            return UnsubscribeNotificationsImpl.execute(subscriptionId);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new ApplicationException(e.getMessage());
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class SendRequest implements CopadoServiceRequest {
        global String name; // Notification Name (Required)
        global Set<Id> recipientIds = new Set<Id>(); // User Ids that will receive the notification (Required)
        global Map<String, String> mergeData = new Map<String, String>(); // Merge data for Notification template (Required)

        // CONSTRUCTOR

        @SuppressWarnings('PMD.EmptyStatementBlock')
        global SendRequest() {
        }

        global SendRequest(String name, Set<Id> recipientIds, Map<String, String> mergeData) {
            this.name = name;
            this.recipientIds = recipientIds;
            this.mergeData = mergeData;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class SubscribeRequest implements CopadoServiceRequest {
        global String notificationName; // Notification Name (Required)
        global String channel; // Email is the only value accepted (Required)
        global Id receiverId; // User Id (Required)
    }

    @JsonAccess(serializable='always' deserializable='always')
    global inherited sharing class SubscribeResult implements CopadoServiceResult {
        global Notification_Subscription__c subscription; // Subscription Record

        // CONSTRUCTOR

        global SubscribeResult(Notification_Subscription__c subscription) {
            this.subscription = subscription;
        }

        global SubscribeResult(Id subscriptionId) {
            this.subscription = new NotificationSubscriptionsSelector().byId(subscriptionId);
        }
    }
}