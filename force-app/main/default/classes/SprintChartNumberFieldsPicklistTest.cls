@IsTest
private class SprintChartNumberFieldsPicklistTest {
    @IsTest 
    private static void testGetDefaultValue(){

        Test.startTest();
            SprintChartNumberFieldsPicklist scfp = new SprintChartNumberFieldsPicklist();
            VisualEditor.DataRow dr = scfp.getDefaultValue();
        Test.stopTest();

        System.assertEquals('',dr.getLabel(),'Label should be empty');
        System.assertEquals('',dr.getValue(),'Value should be empty');
    }

    @IsTest 
    private static void testGetValues(){
        Test.startTest();
            SprintChartNumberFieldsPicklist scfp = new SprintChartNumberFieldsPicklist();
            VisualEditor.DynamicPickListRows dpr = scfp.getValues();
        Test.stopTest();

        System.assert(dpr.size() > 0,'Should have more than 1 field');
    }
}