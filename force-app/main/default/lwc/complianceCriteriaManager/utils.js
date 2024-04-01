import { schema, type2ops, operators, operatorCodes, lightningBoxTypes } from './constants';

/**
 * Returns the list of available operators for a given type.
 *  - A type can be: string, boolean, int, ...
 *  - Possible operators are: equals, not equals, contains, greater than, ...
 * @param {string} fieldType
 * @returns {Array} operators
 */
export function getOperatorListByType(fieldType) {
    let result = [];
    if (Object.hasOwnProperty.call(type2ops, fieldType)) {
        result = type2ops[fieldType];
    }

    result = result.map((operatorType) => operatorCodes[operatorType]);

    return result.map((operatorType) => {
        return { label: operatorType, value: operatorType };
    });
}

/**
 * Returns the lightning-input type depending on the criteria field and operator selected
 * Examples:
 *  - If the fieldType is "deprecated" (Boolean) the lightning-input will always be "checkbox", no matter
 * the operator selected.
 *  - If the fieldType is "description" (String) and the operator selected matches another string (i.e contains),
 * the lightning-input will be "string".
 *  - If the fieldType is "description" (String) and operators assert a boolean condition (i.e isBlank), the
 * lightning-input will be "checkbox".
 * @param {string} fieldType
 * @param {string} operator
 * @returns {string} lightning-input type
 */
export function getValueBoxType(fieldType, operator) {
    if (operator === operators.IS_BLANK || operator === operators.IS_NOT_BLANK) {
        return lightningBoxTypes.CHECKBOX;
    }

    const result = {
        DATE: lightningBoxTypes.DATE,
        DATETIME: lightningBoxTypes.DATETIME,
        INTEGER: lightningBoxTypes.NUMBER,
        DOUBLE: lightningBoxTypes.NUMBER,
        INT: lightningBoxTypes.NUMBER,
        PERCENT: lightningBoxTypes.NUMBER,
        BOOLEAN: lightningBoxTypes.CHECKBOX
    };

    return result[fieldType] || lightningBoxTypes.TEXT;
}

/**
 * Sets the properties `valueBoxType` and `isBoolean` for the given `criteria` param.
 * Pre-requisite: The criteria passed object must have `fieldType` property set.
 * @param {Object} criteria
 */
export function setValueBoxForm(criteria) {
    criteria.valueBoxType = getValueBoxType(criteria.fieldType, criteria.operator);
    criteria.isBoolean = criteria.valueBoxType === lightningBoxTypes.CHECKBOX;
}

/**
 * Returns a filtered list from the provided `nodes` list where only the provided
 * `selectedNode` and `name` nodes will be available.
 * @param {Array} nodes
 * @param {string} selectedNode
 * @returns {Array} nodes
 */
export function filterNodeListByNode(nodes, selectedNode) {
    let result = nodes;
    if (selectedNode !== 'name') {
        result = result.filter((node) => node.label === 'name' || node.label === selectedNode);
    }
    return result;
}

/**
 * Returns a transformed criteria list where the items have the criteria sobject shape.
 *
 * This method provides a huge help when calling an Apex method to save the criterias, as
 * those objects need to have the SObject keys to be handled in the Apex side.
 * @param {Array} criterias
 * @param {string} ruleId
 * @returns
 */
export function criteriaListToSObjectList(criterias, ruleId) {
    return criterias.map((criteria, index) => {
        if (criteria.valueBoxType === lightningBoxTypes.CHECKBOX && !criteria.value) {
            criteria.value = 'false';
        }

        let formatedValue = criteria.value ? criteria.value.trim() : criteria.value;
        if (criteria.operator.toLowerCase() === 'within' || criteria.operator.toLowerCase() === 'excludes') {
            formatedValue = `[${formatedValue}]`;
        }

        const criteriaString = `${criteria.node}.${criteria.field}<${criteria.operator.replace(/ /g, '').toUpperCase()}>${formatedValue}`;

        const result = {
            sObjectType: schema.COMPLIANCE_RULE_CRITERIA.objectApiName
        };

        result[schema.COMPLIANCE_RULE.objectApiName] = ruleId;
        result[schema.COMPLIANCE_CRITERIA_TEXT.fieldApiName] = criteriaString;
        result[schema.COMPLIANCE_CRITERIA_ORDER.fieldApiName] = index + 1;
        result[schema.COMPLIANCE_CRITERIA_NODE.fieldApiName] = criteria.node;
        result[schema.COMPLIANCE_CRITERIA_FIELD.fieldApiName] = criteria.field;
        result[schema.COMPLIANCE_CRITERIA_FIELD_TYPE.fieldApiName] = criteria.fieldType;
        result[schema.COMPLIANCE_CRITERIA_OPERATOR.fieldApiName] = criteria.operator;
        result[schema.COMPLIANCE_CRITERIA_VALUE.fieldApiName] = formatedValue;

        if (criteria.sfId) {
            result.Id = criteria.sfId;
        }

        return result;
    });
}