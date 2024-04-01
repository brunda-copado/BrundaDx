import EDIT from '@salesforce/label/c.EDIT';
import SAVE from '@salesforce/label/c.Save';
import CANCEL from '@salesforce/label/c.Cancel';
import LOADING from '@salesforce/label/c.LOADING';
import CONDITION_FILTER_TITLE from '@salesforce/label/c.QualityGatesConditionFilterTitle';
import CONDITION_FILTER_TITLE_HELPTEXT from '@salesforce/label/c.QualityGatesConditionFilterHelptext';
import CONDITION_FILTER_FILTER_LOGIC_LABEL from '@salesforce/label/c.QualityGatesConditionFilterLogicLabel';
import CONDITION_FILTER_PROPERTY_LABEL from '@salesforce/label/c.QualityGatesConditionPropertyLabel';
import CONDITION_PROPERTY_HELPTEXT from '@salesforce/label/c.QualityGatesConditionPropertyHelptext';
import CONDITION_FILTER_OPERATOR_LABEL from '@salesforce/label/c.QualityGatesConditionOperatorLabel';
import CONDITION_FILTER_VALUE_LABEL from '@salesforce/label/c.QualityGatesConditionValueLabel';
import CONDITION_FILTER_FILE_VALUE from '@salesforce/label/c.QualityGatesConditionFileValue';
import DELETE_CONDITION from '@salesforce/label/c.QualityGatesDeleteCondition';
import EMPTY_CONDITIONS_TITLE from '@salesforce/label/c.QualityGatesEmptyTitle';
import EMPTY_CONDITIONS_BODY from '@salesforce/label/c.QualityGatesEmptyBody';
import ADD_CONDITION_BUTTON from '@salesforce/label/c.QualityGatesAddConditionButton';
import SAVE_SUCCESS_MESSAGE from '@salesforce/label/c.QualityGatesSaveSuccessMessage';
import REPEATED_CONDITIONS_ERROR_MESSAGE from '@salesforce/label/c.QualityGatesRepeatedConditionsErrorMessage';
import MISSED_CONDITIONS_ERROR_MESSAGE from '@salesforce/label/c.QualityGatesMissedConditionsErrorMessage';
import EXTRA_CONDITIONS_ERROR_MESSAGE from '@salesforce/label/c.QualityGatesExtraConditionsErrorMessage';
import WRONG_SYNTAX_ERROR_MESSAGE from '@salesforce/label/c.QualityGatesWrongSyntaxErrorMessage';


export const label = {
    EDIT,
    SAVE,
    CANCEL,
    LOADING,
    CONDITION_FILTER_TITLE,
    CONDITION_FILTER_TITLE_HELPTEXT,
    CONDITION_FILTER_FILTER_LOGIC_LABEL,
    CONDITION_FILTER_PROPERTY_LABEL,
    CONDITION_PROPERTY_HELPTEXT,
    CONDITION_FILTER_OPERATOR_LABEL,
    CONDITION_FILTER_VALUE_LABEL,
    CONDITION_FILTER_FILE_VALUE,
    DELETE_CONDITION,
    EMPTY_CONDITIONS_TITLE,
    EMPTY_CONDITIONS_BODY,
    ADD_CONDITION_BUTTON,
    SAVE_SUCCESS_MESSAGE,
    REPEATED_CONDITIONS_ERROR_MESSAGE,
    MISSED_CONDITIONS_ERROR_MESSAGE,
    EXTRA_CONDITIONS_ERROR_MESSAGE,
    WRONG_SYNTAX_ERROR_MESSAGE
};


export const propertyOptions = [
    { label: 'Type/Extension', value: 'Type'},
    { label: 'Directory', value: 'Directory'},
    { label: 'Name', value: 'Name'}
];

export const operatorOptions = [
    { label: 'Starts With', value: 'startsWith'},
    { label: 'Ends With', value: 'endsWith'},
    { label: 'Equals', value: 'equals'},
    { label: 'Not Equals', value: 'notEquals'},
    { label: 'Contains', value: 'contains'},
    { label: 'Not Contains', value: 'notContains'}
];

export const logicOperator = {
    AND: 'AND',
    OR: 'OR'
};