@isTest
private class UISectionHelperTest {
    @isTest
    private static void fetchUiSectionWithPlatform() {
        System.runAs(getTestUser()) {
            // Setup
            UISection__mdt mockUiSectionWithTestTool = mockUiSection();

            // Exercise
            List<UISection__mdt> uiSections = UISectionHelper.fetchUISection('Mock Platform', null, 'Mock Location');

            // Verify
            System.assertEquals(mockUiSectionWithTestTool.MasterLabel, uiSections[0].MasterLabel, 'Possible issue on UiSectionsSelector!');
        }
    }

    @isTest
    private static void fetchUiSectionWithTestTool() {
        System.runAs(getTestUser()) {
            // Setup
            UISection__mdt mockUiSectionWithTestTool = mockUiSection();

            // Exercise
            List<UISection__mdt> uiSections = UISectionHelper.fetchUISection('', 'Mock Test Tool', 'Mock Location');

            // Verify
            System.assertEquals(mockUiSectionWithTestTool.MasterLabel, uiSections[0].MasterLabel, 'Possible issue on UiSectionsSelector!');
        }
    }

    @isTest
    private static void fetchUiSectionWithUILocationOnly() {
        System.runAs(getTestUser()) {
            // Setup
            List<UISection__mdt> mockUiSections = mockUiSections();

            // Exercise
            List<UISection__mdt> uiSections = UISectionHelper.fetchUISection(null, null, 'Mock Location');

            // Verify
            System.assertEquals(mockUiSections.size(), uiSections.size(), 'Possible issue on UiSectionsSelector!');
        }
    }

    private static UISection__mdt mockUiSection() {
        UISection__mdt result = new UISection__mdt(
            MasterLabel = 'Mock Section',
            Location__c = 'CCM.MockSection',
            Component__c = 'c:mockSection'
        );

        UiSectionsSelector.mock(new List<UISection__mdt>{ result });

        return result;
    }

    private static List<UISection__mdt> mockUiSections() {
        UISection__mdt result1 = new UISection__mdt(
            MasterLabel = 'Mock Section',
            Location__c = 'CCM.MockSection',
            Component__c = 'c:mockSection'
        );

        UISection__mdt result2 = new UISection__mdt(
            MasterLabel = 'Mock Section 2',
            Location__c = 'CCM.MockSection',
            Component__c = 'c:mockSection'
        );

        List<UISection__mdt> results = new List<UISection__mdt>{result1, result2};
        UiSectionsSelector.mock(results);

        return results;
    }

    @TestSetup
    private static void setupData() {
        setupUser();
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];

        return adminUser;
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}