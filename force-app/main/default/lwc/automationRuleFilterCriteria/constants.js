import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import CLOSE from '@salesforce/label/c.CLOSE';
import CLEAR_ALL from '@salesforce/label/c.Clear_All';
import INSUFFICIENT_PERMISSION from '@salesforce/label/c.No_necessary_permission_for_automation_rule';
import ADVANCED_CRITERIA from '@salesforce/label/c.Advanced_Criteria';
import NO_CRITERIA_DEFINED from '@salesforce/label/c.No_Criteria_Defined';
import NO_CRITERIA_DEFINED_BODY from '@salesforce/label/c.No_Criteria_Defined_Body';
import CONFIGURE_CRITERIA from '@salesforce/label/c.Configure_Criteria';
import MAIN_OBJECT from '@salesforce/label/c.MainObject';
import TAKE_ACTION_WHEN from '@salesforce/label/c.Take_Action_When';
import FIELD_LABEL from '@salesforce/label/c.Field_Label';
import FIELD_API_NAME from '@salesforce/label/c.Field_API_Name';
import ADD_CONDITION from '@salesforce/label/c.Add_Condition';
import CONDITION_FILTER_OPERATOR_LABEL from '@salesforce/label/c.QualityGatesConditionOperatorLabel';
import CONDITION_FILTER_VALUE_LABEL from '@salesforce/label/c.QualityGatesConditionValueLabel';
import DELETE_CONDITION from '@salesforce/label/c.QualityGatesDeleteCondition';
import CUSTOM_CONDITION from '@salesforce/label/c.Custom_Condition';
import CHECK_SYNTAX from '@salesforce/label/c.Check_Syntax';
import CRITERIA_CANNNOT_BE_CONFIGURED from '@salesforce/label/c.Criteria_Cannnot_Be_Configured';
import CONFIGURE_CRITERIA_ERROR_BODY from '@salesforce/label/c.Configure_Criteria_Error_Body';
import FILTER_CRITERIA_INFO_MESSAGE from '@salesforce/label/c.Filter_Criteria_Info_Message';
import CONFIGURE_CRITERIA_ERROR_MAIN_OBJECT_MATCH from '@salesforce/label/c.Configure_Criteria_Error_Main_Object_Match';
import CRITERIA_SUCCESSFULLY_CREATED from '@salesforce/label/c.Criteria_Successfully_Created';
import CHECK_SYNTAX_SUCCESS_MESSAGE from '@salesforce/label/c.Check_Syntax_Success_Message';
import CHECK_SYNTAX_ERROR_MESSAGE from '@salesforce/label/c.Check_Syntax_Error_Message';
import ALL_CONDITIONS_ARE_MET from '@salesforce/label/c.All_Conditions_Are_Met';
import ANY_CONDITION_IS_MET from '@salesforce/label/c.Any_Condition_Is_Met';
import CUSTOM_LOGIC_IS_MET from '@salesforce/label/c.Custom_Logic_Is_Met';
import USER_STORY from '@salesforce/label/c.USER_STORY';
import EQUALS from '@salesforce/label/c.Equals';
import DOES_NOT_EQUAL from '@salesforce/label/c.Does_Not_Equal';
import GREATER_THAN from '@salesforce/label/c.Greater_Than';
import GREATER_OR_EQUAL from '@salesforce/label/c.Greater_Or_Equal';
import LESS_THAN from '@salesforce/label/c.Less_Than';
import LESS_OR_EQUAL from '@salesforce/label/c.Less_Or_Equal';
import CONTAINS from '@salesforce/label/c.Contains';
import DOES_NOT_CONTAIN from '@salesforce/label/c.Does_Not_Contain';
import MAIN_OBJECT_HELP_TEXT from '@salesforce/label/c.Main_Object_Help_Text';
import TAKE_ACTION_WHEN_HELP_TEXT from '@salesforce/label/c.Take_Action_When_Help_Text';
import CUSTOM_CONDITION_HELP_TEXT from '@salesforce/label/c.Custom_Condition_Help_Text';
import FIELD_LABEL_HELP_TEXT from '@salesforce/label/c.Field_Label_Help_Text';
import ERROR_SEARCHING_RECORDS from '@salesforce/label/c.Error_Searching_Records';

import USER_STORY_OBJECT from '@salesforce/schema/User_Story__c';
import AUTOMATION_RULE_OBJECT from '@salesforce/schema/Automation_Rule__c';
import AUTOMATION_RULE_ACTIVE from '@salesforce/schema/Automation_Rule__c.Active__c';
import AUTOMATION_RULE_SOURCE_ACTION from '@salesforce/schema/Automation_Rule__c.Source_Action__c';
import AUTOMATION_RULE_AUTOMATION_CONNECTOR from '@salesforce/schema/Automation_Rule__c.Automation_Connector__c';
import AUTOMATION_RULE_FILTER_CRITERIA from '@salesforce/schema/Automation_Rule__c.Filter_Criteria__c';

export const label = {
    EDIT,
    SAVE,
    CANCEL,
    CLOSE,
    CLEAR_ALL,
    INSUFFICIENT_PERMISSION,
    ADVANCED_CRITERIA,
    NO_CRITERIA_DEFINED,
    NO_CRITERIA_DEFINED_BODY,
    CONFIGURE_CRITERIA,
    MAIN_OBJECT,
    TAKE_ACTION_WHEN,
    FIELD_LABEL,
    FIELD_API_NAME,
    ADD_CONDITION,
    CONDITION_FILTER_OPERATOR_LABEL,
    CONDITION_FILTER_VALUE_LABEL,
    DELETE_CONDITION,
    CUSTOM_CONDITION,
    CHECK_SYNTAX,
    CRITERIA_CANNNOT_BE_CONFIGURED,
    CONFIGURE_CRITERIA_ERROR_BODY,
    FILTER_CRITERIA_INFO_MESSAGE,
    CONFIGURE_CRITERIA_ERROR_MAIN_OBJECT_MATCH,
    CRITERIA_SUCCESSFULLY_CREATED,
    CHECK_SYNTAX_SUCCESS_MESSAGE,
    CHECK_SYNTAX_ERROR_MESSAGE,
    EQUALS,
    DOES_NOT_EQUAL,
    GREATER_THAN,
    GREATER_OR_EQUAL,
    LESS_THAN,
    LESS_OR_EQUAL,
    CONTAINS,
    DOES_NOT_CONTAIN,
    MAIN_OBJECT_HELP_TEXT,
    TAKE_ACTION_WHEN_HELP_TEXT,
    CUSTOM_CONDITION_HELP_TEXT,
    FIELD_LABEL_HELP_TEXT,
    ERROR_SEARCHING_RECORDS
};

export const schema = {
    USER_STORY_OBJECT,
    AUTOMATION_RULE_OBJECT,
    AUTOMATION_RULE_ACTIVE,
    AUTOMATION_RULE_FILTER_CRITERIA,
    AUTOMATION_RULE_SOURCE_ACTION,
    AUTOMATION_RULE_AUTOMATION_CONNECTOR
};

export const fields = [AUTOMATION_RULE_ACTIVE, AUTOMATION_RULE_FILTER_CRITERIA, AUTOMATION_RULE_SOURCE_ACTION, AUTOMATION_RULE_AUTOMATION_CONNECTOR];

export const AND = 'AND';
export const OR = 'OR';
export const CUSTOM = 'CUSTOM';
export const REFERENCE = 'REFERENCE';

export const conditionLogicOptions = [
    { label: ALL_CONDITIONS_ARE_MET, value: AND },
    { label: ANY_CONDITION_IS_MET, value: OR },
    { label: CUSTOM_LOGIC_IS_MET, value: CUSTOM }
];

export const conditionLookUpOperators = [
    { label: label.EQUALS, value: 'equals' },
    { label: label.DOES_NOT_EQUAL, value: 'notEquals' }
];

// NOTE: if you are adding new action here, make sure to also add the action in the AutomationRuleConfiguration component, in _sourceActionMatchFilterCriteriaObject() method.
export const mainObjectOptionsByAction = {
    Commit: [{ label: USER_STORY, value: USER_STORY_OBJECT.objectApiName }],
    Promotion: [{ label: USER_STORY, value: USER_STORY_OBJECT.objectApiName }],
    PromotionDeployment: [{ label: USER_STORY, value: USER_STORY_OBJECT.objectApiName }],
    SubmitUserStories: [{ label: USER_STORY, value: USER_STORY_OBJECT.objectApiName }]
};