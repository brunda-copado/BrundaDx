public inherited sharing class CopadoAlert {
    public enum Variant {
        ERROR,
        WARNING,
        INFO,
        SUCCESS
    }

    @AuraEnabled
    public String message;
    @AuraEnabled
    public String variant;
    @AuraEnabled
    public Boolean dismissible;

    public CopadoAlert() {
        this.dismissible = false;
    }

    public CopadoAlert message(String message) {
        this.message = message;
        return this;
    }

    public CopadoAlert variant(Variant variant) {
        this.variant = variant.name().toLowerCase();
        return this;
    }

    public CopadoAlert dismissible() {
        this.dismissible = true;
        return this;
    }
}