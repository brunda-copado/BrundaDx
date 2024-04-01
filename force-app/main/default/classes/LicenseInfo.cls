public inherited sharing class LicenseInfo {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public Integer used;
    @AuraEnabled
    public Integer available;

    public LicenseInfo(String name, Integer used, Integer available) {
        this.name = name;
        this.used = used;
        this.available = available;
    }
}