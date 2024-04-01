public with sharing class Notification {
    private String name;
    private Set<Id> recipientIds;
    private Map<String, String> mergeJson;

    // CONSTRUCTOR

    public Notification(String name, Set<Id> recipientIds, Map<String, String> mergeJson) {
        this.name = name;
        this.mergeJson = mergeJson;
        this.recipientIds = recipientIds;
    }

    // PUBLIC

    public void send() {
        CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest(name, recipientIds, mergeJson);

        CopadoNotifications.send(request);
    }
}