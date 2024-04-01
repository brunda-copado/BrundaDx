public with sharing class CustomLookupComponentHelper {
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> search(CustomLookupQueryConfiguration queryConfig, String objectLabel) {
        return search(queryConfig, objectLabel, null);
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> search(CustomLookupQueryConfiguration queryConfig, String objectLabel, String iconName) {
        return search(queryConfig, objectLabel, iconName, null);
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> search(CustomLookupQueryConfiguration queryConfig, String objectLabel, String iconName, String subtitleField) { // NOPMD
        try {
            List<SObject> searchResults = Database.query(queryConfig.getFormattedQuery());
            List<LookupSearchResult> result = new List<LookupSearchResult>();

            String icon = String.isBlank(iconName) ? 'standard:choice' : iconName;
            for (SObject obj : searchResults) {
                String name = String.valueOf(obj.get('Name'));
                String subtitle = String.isNotBlank(subtitleField) ? objectLabel + ' • ' + String.valueOf(obj.get(subtitleField)) :  objectLabel + ' • ' + name;
                result.add(new LookupSearchResult(obj.Id, objectLabel, icon, name, subtitle));
            }

            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }


}