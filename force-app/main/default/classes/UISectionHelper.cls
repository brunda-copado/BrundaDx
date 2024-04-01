public with sharing class UISectionHelper {
    @AuraEnabled
    public static List<UISection__mdt> fetchUISection(String platform, String testTool, String uiSectionId) {
        try {
            // Note: Doing it in two if statements because SOQL on CMDT does not support OR condition.

            List<UISection__mdt> uiSections = new List<UISection__mdt>();
            if (platform != null) {
                uiSections = new UiSectionsSelector().byPlatformAndLocation(platform, uiSectionId);
            }

            if (testTool != null) {
                uiSections = new UiSectionsSelector().byTestToolAndLocation(testTool, uiSectionId);
            }

            if(null == testTool && null == platform){
                uiSections = new UiSectionsSelector().byLocationOnly(uiSectionId);
            }

            return uiSections.isEmpty() ? null : uiSections;
        } catch (Exception e) {
            throw new AuraHandledException(String.format(Label.UISectionNotFound, new List<Object>{ platform, uiSectionId, e.getMessage() }));
        }
    }
}