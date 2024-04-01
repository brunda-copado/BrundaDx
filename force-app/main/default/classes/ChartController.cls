// Note: These parameters are returned to a javascript controller from SprintWallChartController so they need to be public
@SuppressWarnings('PMD.ExcessivePublicCount')
public virtual with sharing class ChartController {

    // Chart Data request wrapper
    public with sharing virtual class ChartDataRequest {
        @AuraEnabled
        public String objectId { get; set; }
        @AuraEnabled
        public String objectName { get; set; }
        @AuraEnabled
        public String chartFileName { get; set; }
        @AuraEnabled
        public String chartDataJson { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String plannedVelocityField { get; set; }
        @AuraEnabled
        public String actualVelocityField { get; set; }
        @AuraEnabled
        public String sprintPlannedVelocityField { get; set; }
        @AuraEnabled
        public String sprintActualVelocityField { get; set; }
        @AuraEnabled
        public List<String> xAxisValues { get; set; }
        // Based on Daily/Weekly/Monthly
        @AuraEnabled
        public String plotInterval { get; set; }
        @AuraEnabled
        public String lastDayOfWeek { get; set; }

        
        public ChartDataRequest(){
            this.plotInterval = 'Days';
            this.lastDayOfWeek = 'Friday';
            this.chartDataJson = '';
        }
    }

    // Chart data response wrapper
    public with sharing class ChartDataResponse {
        
        @AuraEnabled
        public String chartDataJson { get; set; }
        @AuraEnabled
        public List<String> xAxisValues { get; set; }
    }


    public with sharing class ChartDataResponseElement{
        @AuraEnabled
        public String x { get; set; }
        @AuraEnabled
        public String y { get; set; }
        public ChartDataResponseElement(String xAxisValue, String yAxisValue) {
            this.x = xAxisValue;
            this.y = yAxisValue;
        }
    }   
}