@isTest
public class FilterComponentControllerTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createDefaultTestData();
        }
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }

    private static TestUtilities createDefaultTestData() {
        TestUtilities tu = new TestUtilities();

        // Create Team records
        tu.insertSObject(
            'Team__c',
            new Map<String, Object>{ 'Name' => 'Team1', 'Active__c' => true }
        );
        
        tu.insertSObject(
            'Team__c',
            new Map<String, Object>{ 'Name' => 'Team2', 'Active__c' => true }
        );

        // Create current sprint record
        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint1',
                                    'Start_Date__c' => Date.today().addDays(-8),
                                    'End_Date__c' => Date.today().addDays(8),
                                    'Team__c' => tu.item('Team__c', 0).Id
                                }
        );

        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint2',
                                    'Start_Date__c' => Date.today().addDays(-8),
                                    'End_Date__c' => Date.today().addDays(8),
                                    'Team__c' => tu.item('Team__c', 1).Id
                                }
        );

        // Create user story to fill sobjectlist
        tu.insertSObjects(
            'User_Story__c',
            4,
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 0).Id,
                'Team__c' => tu.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        tu.insertSObjects(
            'User_Story__c',
            3,
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Draft',
                'Priority__c' =>2,
                'Is_Bundle__c' => false,
                'Validate_Only__c' => true,
                'Sprint__c' => tu.item('Sprint__c', 1).Id,
                'Team__c' => tu.item('Team__c', 1).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        tu.insertSObjects(
            'User_Story__c',
            1,
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Draft',
                'Priority__c' =>2,
                'Is_Bundle__c' => false,
                'Validate_Only__c' => true,
                'Sprint__c' => tu.item('Sprint__c', 1).Id,
                'Team__c' => tu.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

         tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
        );

        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint 4', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
        );

        tu.insertSObject(
            'Kanban_Board__c',
            new Map<String, Object>{ 'Name' => 'Kanban Board For Sprint 3' }
        );

        tu.insertSObject(
            'Kanban_Board__c',
            new Map<String, Object>{ 'Name' => 'Kanban Board For Sprint 4', 'Sprint__c' => tu.item('Sprint__c', 3).Id }
        );

        return tu;
    }

    @isTest
    public static void testgetFields(){
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            List<FilterComponentController.FieldListWrapper> fields=FilterComponentController.getFields();
            system.assert(fields.size()>0);
        }
    }
    
    @isTest
    public static void testfilterUserStoryRecord(){

        User standardUser = getStandardUser();
        System.runAs(standardUser) {

            Sprint__c sprint = [SELECT Id, Name FROM Sprint__c WHERE Name = 'Sprint2' LIMIT 1];

            List<FilterComponentQueryConfiguration> filterComponentQueryConfigurations = new List<FilterComponentQueryConfiguration>();
            FilterComponentQueryConfiguration doubleEqualFilter = new FilterComponentQueryConfiguration();
            doubleEqualFilter.fieldValue='2';
            doubleEqualFilter.fieldTypeSelected='DOUBLE';
            doubleEqualFilter.fieldLabelSelected='Priority';
            doubleEqualFilter.fieldSelected='Priority__c';
            doubleEqualFilter.operatorLabelSelected='Equal';
            doubleEqualFilter.operatorUsed='=';
            filterComponentQueryConfigurations.add(doubleEqualFilter);
            
            FilterComponentQueryConfiguration doubleContainsFilter= new FilterComponentQueryConfiguration();
            doubleContainsFilter.fieldValue='2';
            doubleContainsFilter.fieldTypeSelected='DOUBLE';
            doubleContainsFilter.fieldLabelSelected='Priority';
            doubleContainsFilter.fieldSelected='Priority__c';
            doubleContainsFilter.operatorLabelSelected='Contains';
            doubleContainsFilter.operatorUsed='Like';
            filterComponentQueryConfigurations.add(doubleContainsFilter);
            
            FilterComponentQueryConfiguration booleanEqualFilter= new FilterComponentQueryConfiguration();
            booleanEqualFilter.fieldValue='false';
            booleanEqualFilter.fieldTypeSelected='BOOLEAN';
            booleanEqualFilter.fieldLabelSelected='Is Bundle';
            booleanEqualFilter.fieldSelected='Is_Bundle__c';
            booleanEqualFilter.operatorLabelSelected='Equal';
            booleanEqualFilter.operatorUsed='=';
            filterComponentQueryConfigurations.add(booleanEqualFilter);
            
            FilterComponentQueryConfiguration booleanNotEqualFilter= new FilterComponentQueryConfiguration();
            booleanNotEqualFilter.fieldValue='false';
            booleanNotEqualFilter.fieldTypeSelected='BOOLEAN';
            booleanNotEqualFilter.fieldLabelSelected='Validate Only';
            booleanNotEqualFilter.fieldSelected='Validate_Only__c';
            booleanNotEqualFilter.operatorLabelSelected='Does Not Contains';
            booleanNotEqualFilter.operatorUsed='NotLike';
            filterComponentQueryConfigurations.add(booleanNotEqualFilter);

            String jsonString = '{"filterString":"'+System.JSON.serialize(filterComponentQueryConfigurations).replace('"', '\\"')+'","ownerString":"All User Stories","recordId":"'+sprint.Id+'","selectFieldSet":"Sprint_Wall_Columns","recordLimit":10000}';

            List<User_Story__c> userStories = FilterComponentController.filterUserStoryRecord(jsonString);
        
            System.assertEquals(4, userStories.size());

        }
    }
    
    @isTest
    public static void testfilterUserStoryRecordWithPicklist(){

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            String[] valuesForPicklist = new String[] {'Draft'};
            Sprint__c sprint = [SELECT Id, Name FROM Sprint__c WHERE Name = 'Sprint2' LIMIT 1];

            List<FilterComponentQueryConfiguration> fieldOperatorValueWrappers = new List<FilterComponentQueryConfiguration>();
            FilterComponentQueryConfiguration obj= new FilterComponentQueryConfiguration();
            obj.fieldLabelSelected='Status';
            obj.fieldSelected='Status__c';
            obj.fieldValue='Draft';
            obj.operatorLabelSelected='Equal';
            obj.operatorUsed='=';
            obj.fieldSelectedValues = valuesForPicklist;
            obj.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj);
            
            FilterComponentQueryConfiguration obj1= new FilterComponentQueryConfiguration();
            obj1.fieldLabelSelected='Status';
            obj1.fieldValue='Draft';
            obj1.fieldSelected='Status__c';
            obj1.operatorLabelSelected='Not Equal';
            obj1.operatorUsed='!=';
            obj1.fieldSelectedValues = valuesForPicklist;
            obj1.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj1);

            FilterComponentQueryConfiguration obj2= new FilterComponentQueryConfiguration();
            obj2.fieldLabelSelected='Status';
            obj2.fieldValue='Draft';
            obj2.fieldSelected='Status__c';
            obj2.operatorLabelSelected='Less Than';
            obj2.operatorUsed='<';
            obj2.fieldSelectedValues = valuesForPicklist;
            obj2.fieldTypeSelected='PICKLIST' ;
            
            FilterComponentQueryConfiguration obj3= new FilterComponentQueryConfiguration();
            obj3.fieldLabelSelected='Status';
            obj3.fieldValue='Draft';
            obj3.fieldSelected='Status__c';
            obj3.operatorLabelSelected='Greater Than';
            obj3.operatorUsed='>';
            obj3.fieldSelectedValues = valuesForPicklist;
            obj3.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj3);

            
            FilterComponentQueryConfiguration obj4= new FilterComponentQueryConfiguration();
            obj4.fieldLabelSelected='Status';
            obj4.fieldValue='Draft';
            obj4.fieldSelected='Status__c';
            obj4.operatorLabelSelected='Less Than or Equal';
            obj4.operatorUsed='<=';
            obj4.fieldSelectedValues = valuesForPicklist;
            obj4.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj4);
            
            FilterComponentQueryConfiguration obj5= new FilterComponentQueryConfiguration();
            obj5.fieldLabelSelected='Status';
            obj5.fieldValue='Draft';
            obj5.fieldSelected='Status__c';
            obj5.operatorLabelSelected='Greater Than or Equal';
            obj5.operatorUsed='>=';
            obj5.fieldSelectedValues = valuesForPicklist;
            obj5.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj5);
            
            FilterComponentQueryConfiguration obj6= new FilterComponentQueryConfiguration();
            obj6.fieldLabelSelected='Status';
            obj6.fieldValue='Draft';
            obj6.fieldSelected='Status__c';
            obj6.operatorLabelSelected='Contains';
            obj6.operatorUsed='Like';
            obj6.fieldSelectedValues = valuesForPicklist;
            obj6.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj6);
            
            FilterComponentQueryConfiguration obj7= new FilterComponentQueryConfiguration();
            obj7.fieldLabelSelected='Status';
            obj7.fieldSelected='Status__c';
            obj7.fieldValue='Draft';
            obj7.operatorLabelSelected='Does Not Contains';
            obj7.operatorUsed='NotLike';
            obj7.fieldSelectedValues = valuesForPicklist;
            obj7.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj7);
            
            FilterComponentQueryConfiguration obj8= new FilterComponentQueryConfiguration();
            obj8.fieldLabelSelected='Status';
            obj8.fieldSelected='Status__c';
            obj8.fieldValue='Draft';
            obj8.operatorLabelSelected='Starts With';
            obj8.operatorUsed='StartsWith';
            obj8.fieldSelectedValues = valuesForPicklist;
            obj8.fieldTypeSelected='PICKLIST' ;
            fieldOperatorValueWrappers.add(obj8);
        
            String jsonString = '{"filterString":"'+System.JSON.serialize(fieldOperatorValueWrappers).replace('"', '\\"')+'","ownerString":"All User Stories","recordId":"'+sprint.Id+'","selectFieldSet":"Sprint_Wall_Columns","recordLimit":10000}';

            List<User_Story__c> userStories = FilterComponentController.filterUserStoryRecord(jsonString);
            System.assertEquals(0,userStories.size());
        }
    }
}