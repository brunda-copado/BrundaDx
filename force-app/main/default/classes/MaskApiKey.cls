public with sharing class MaskApiKey {
    
    private String apiKey;
    private Boolean usePlaceholder;

    private static Boolean enforcePersonalSettings { 
        get {
            if(null == enforcePersonalSettings){
                Personal_Settings__c personalSettings = Personal_Settings__c.getInstance(UserInfo.getUserId()); 
                enforcePersonalSettings = personalSettings != null && personalSettings.MaskApiKey__c != null && personalSettings.MaskApiKey__c == true;
            }
            return enforcePersonalSettings;
        } private set;
    }

    private static Boolean enforceProfileSettings { 
        get {
            if(null == enforceProfileSettings){
                Personal_Settings__c profileSettings = Personal_Settings__c.getInstance(UserInfo.getProfileId()); 
                enforceProfileSettings = profileSettings != null && profileSettings.MaskApiKey__c != null && profileSettings.MaskApiKey__c == true;
            }
            return enforceProfileSettings;
        } private set;
    }

    private static Boolean enforceOrgLevelSettings { 
        get {
            if(null == enforceOrgLevelSettings){
                Personal_Settings__c orgLevelSettings = Personal_Settings__c.getInstance(UserInfo.getOrganizationId()); 
                enforceOrgLevelSettings = orgLevelSettings != null && orgLevelSettings.MaskApiKey__c != null && orgLevelSettings.MaskApiKey__c == true;
            }
            return enforceOrgLevelSettings;
        } private set;
    }

    public static Boolean enforceMask {
        get {
            if(null == enforceMask){
                enforceMask = (enforcePersonalSettings || enforceProfileSettings || enforceOrgLevelSettings);
            }
            return enforceMask;
        } private set;
    }

    // CTOR

    public MaskApiKey(String apiKey) {
        this.apiKey = apiKey;
        this.usePlaceholder = false;
    }

    // PUBLIC

    public MaskApiKey usingPlaceholder() {
        this.usePlaceholder = true;
        return this;
    }

    public String execute() {
        String result = this.apiKey;

        if (enforceMask()) {
            result = this.usePlaceholder ? placeholder() : mask(this.apiKey);
        }

        return result;
    }

    // PRIVATE

    private Boolean enforceMask() {
        return enforceMask;
    }

    private String placeholder() {
        return Label.ApiKeyPlaceholder;
    }

    private String mask(String apiKey) {
        return String.isNotBlank(apiKey) ? '*'.repeat(apiKey.length()) : apiKey;
    }
}