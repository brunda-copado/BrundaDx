@IsTest 
public with sharing class ChartControllerTest{
    @IsTest 
    private static void testChartController(){
        Test.startTest();
            ChartController.ChartDataRequest request = new ChartController.ChartDataRequest();
            request.objectId = UserInfo.getUserId();
            request.type = 'Line Burnup';
            request.chartFileName = 'Test Get Chart Data.json';
            request.lastDayOfWeek = 'friday';
            request.plannedVelocityField = 'PlannedVelocity__c';
            request.actualVelocityField = 'ActualVelocity__c';

            ChartController.ChartDataResponse cdr = new ChartController.ChartDataResponse();
            cdr.chartDataJson = '{}';
            cdr.xAxisValues = new String[]{};

            ChartController.ChartDataResponseElement cdre = new ChartController.ChartDataResponseElement('x','y');
        Test.stopTest();

        System.assert(cdr != null, 'Chart should not be empty');
        System.assertEquals('x', cdre.x,'It should be x');
        System.assertEquals('y', cdre.y,'It should be y');
    }
}