@isTest
private class JobExecutionFieldsPicklistTest {
    @IsTest
    private static void testGetDefaultValue() {
        // Exercise

        Test.startTest();
        VisualEditor.DataRow rows = new JobExecutionFieldsPicklist().getDefaultValue();
        Test.stopTest();

        // Verify

        System.assertEquals('', rows.getLabel(), 'Label should be empty');
        System.assertEquals('', rows.getValue(), 'Value should be empty');
    }

    @IsTest
    private static void testGetValues() {
        // Exercise

        Test.startTest();
        VisualEditor.DynamicPickListRows rows = new JobExecutionFieldsPicklist().getValues();
        Test.stopTest();

        // Verify

        List<String> values = new List<String>();
        for (Integer i = 0; i < rows.size(); i++) {
            values.add(String.valueOf(rows.getDataRows()[i].getValue()));
        }

        System.assertEquals(true, rows.size() > 0, 'There are rows available');
        System.assertEquals(false, values.contains('CreatedById'), 'CreatedById should not be present');
        System.assertEquals(false, values.contains('LastModifiedById'), 'LastModifiedById should not be present');
        System.assertEquals(false, values.contains('OwnerId'), 'OwnerId should not be present');
        System.assertEquals(true, values.contains('Name'), 'Name should be present');
        System.assertEquals(true, values.contains(Settings.ns + 'Promotion__c'), 'Promotion__c should be present');
        System.assertEquals(true, values.contains(Settings.ns + 'Snapshot__c'), 'Snapshot__c should be present');
    }
}