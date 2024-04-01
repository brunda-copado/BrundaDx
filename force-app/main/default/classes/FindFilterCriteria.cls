public with sharing class FindFilterCriteria {
    private String objectName;

    // PUBLIC

    public FindFilterCriteria objectName(String objectName) {
        this.objectName = objectName;
        return this;
    }

    public String fromAutomationRule(Automation_Rule__c automationRule) {
        FilterCriteria filterCriteria = (FilterCriteria) JSON.deserialize(automationRule.Filter_Criteria__c, FilterCriteria.class);
        return filterCriteria.mainObject == objectName && String.isNotBlank(filterCriteria.whereCondition) ? filterCriteria.whereCondition : '';
    }

    public class FilterCriteria {
        public String mainObject;
        public String whereCondition;
    }
}