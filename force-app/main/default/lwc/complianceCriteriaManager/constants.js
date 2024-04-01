import CCH_MISSING_API_KEY from '@salesforce/label/c.CCH_MISSING_API_KEY';
import CCH_CRITERIA_SECTION_TITLE from '@salesforce/label/c.CCH_CRITERIA_SECTION_TITLE';
import CCH_METADATA_TYPE_PARAMETER from '@salesforce/label/c.CCH_METADATA_TYPE_PARAMETER';
import CCH_NODE_PARAMETER from '@salesforce/label/c.Node';
import CCH_FIELD_PARAMETER from '@salesforce/label/c.Field';
import CCH_OPERATOR_PARAMETER from '@salesforce/label/c.Operator';
import CCH_VALUE_PARAMETER from '@salesforce/label/c.VALUE';
import CCH_RESET from '@salesforce/label/c.RESET';
import CCH_SAVE from '@salesforce/label/c.CCH_SAVE';
import CCH_NEW_ROW from '@salesforce/label/c.CCH_NEW_ROW';
import CCH_CRITERIA_LOGIC from '@salesforce/label/c.CCH_CRITERIA_LOGIC';
import CCH_SCOPE_HIDDEN_MESSAGE from '@salesforce/label/c.CCH_SCOPE_HIDDEN_MESSAGE';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';

import COMPLIANCE_RULE from '@salesforce/schema/Compliance_Rule__c';
import COMPLIANCE_RULE_METADATA_TYPE from '@salesforce/schema/Compliance_Rule__c.Metadata_Type__c';
import COMPLIANCE_RULE_CRITERIA_LOGIC from '@salesforce/schema/Compliance_Rule__c.Filter_Criteria__c';
import COMPLIANCE_RULE_CRITERIA from '@salesforce/schema/Compliance_Rule_Criteria__c';
import COMPLIANCE_CRITERIA_NODE from '@salesforce/schema/Compliance_Rule_Criteria__c.Node__c';
import COMPLIANCE_CRITERIA_FIELD from '@salesforce/schema/Compliance_Rule_Criteria__c.Field__c';
import COMPLIANCE_CRITERIA_FIELD_TYPE from '@salesforce/schema/Compliance_Rule_Criteria__c.Field_Type__c';
import COMPLIANCE_CRITERIA_OPERATOR from '@salesforce/schema/Compliance_Rule_Criteria__c.Operator__c';
import COMPLIANCE_CRITERIA_VALUE from '@salesforce/schema/Compliance_Rule_Criteria__c.Value__c';
import COMPLIANCE_CRITERIA_TEXT from '@salesforce/schema/Compliance_Rule_Criteria__c.Criteria__c';
import COMPLIANCE_CRITERIA_ORDER from '@salesforce/schema/Compliance_Rule_Criteria__c.Order__c';
import COMPLIANCE_CRITERIA_NAME from '@salesforce/schema/Compliance_Rule_Criteria__c.Name';

export const label = {
    CCH_MISSING_API_KEY,
    CCH_SCOPE_HIDDEN_MESSAGE,
    CCH_CRITERIA_SECTION_TITLE,
    CCH_METADATA_TYPE_PARAMETER,
    CCH_NODE_PARAMETER,
    CCH_FIELD_PARAMETER,
    CCH_OPERATOR_PARAMETER,
    CCH_VALUE_PARAMETER,
    CCH_RESET,
    CCH_SAVE,
    CCH_NEW_ROW,
    CCH_CRITERIA_LOGIC,
    CANCEL,
    SAVE
};

export const schema = {
    COMPLIANCE_RULE,
    COMPLIANCE_RULE_METADATA_TYPE,
    COMPLIANCE_RULE_CRITERIA_LOGIC,
    COMPLIANCE_RULE_CRITERIA,
    COMPLIANCE_CRITERIA_NODE,
    COMPLIANCE_CRITERIA_FIELD,
    COMPLIANCE_CRITERIA_FIELD_TYPE,
    COMPLIANCE_CRITERIA_OPERATOR,
    COMPLIANCE_CRITERIA_VALUE,
    COMPLIANCE_CRITERIA_TEXT,
    COMPLIANCE_CRITERIA_ORDER,
    COMPLIANCE_CRITERIA_NAME
};

export const emptyCriteria = {
    Id: 1,
    node: '',
    field: '',
    operator: '',
    value: '',
    fieldList: [],
    operatorList: [],
    fieldType: 'STRING',
    valueBoxType: 'text',
    isBoolean: false,
    valueCheckboxValue: false,
    sfId: ''
};

export const operators = {
    EQUALS: 'equals',
    NOT_EQUALS: 'not equal to',
    STARTS_WITH: 'starts with',
    CONTAINS: 'contains',
    NOT_CONTAINS: 'does not contain',
    IS_BLANK: 'is blank',
    IS_NOT_BLANK: 'is not blank',
    LESS_THAN: 'less than',
    GREATER_THAN: 'greater than',
    LESS_OR_EQUAL: 'less or equal',
    GREATER_OR_EQUAL: 'greater or equal',
    INCLUDES: 'includes',
    EXCLUDES: 'excludes',
    WITHIN: 'within'
};

export const operatorCodes = {
    e: operators.EQUALS,
    n: operators.NOT_EQUALS,
    s: operators.STARTS_WITH,
    c: operators.CONTAINS,
    k: operators.NOT_CONTAINS,
    ib: operators.IS_BLANK,
    inb: operators.IS_NOT_BLANK,
    l: operators.LESS_THAN,
    g: operators.GREATER_THAN,
    m: operators.LESS_OR_EQUAL,
    h: operators.GREATER_OR_EQUAL,
    i: operators.INCLUDES,
    x: operators.EXCLUDES,
    w: operators.WITHIN
};

export const type2ops = {
    ANYTYPE: ['e', 'n', 's', 'c', 'k', 'l', 'g', 'm', 'n', 'h', 'u', 'x', 'w'],
    BASE64BINARY: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    BOOLEAN: ['e', 'n'],
    DATE: ['e', 'n', 'l', 'g', 'm', 'h'],
    DATETIME: ['e', 'n', 'l', 'g', 'm', 'h'],
    DOUBLE: ['e', 'n', 'l', 'g', 'm', 'h'],
    ID: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    INTEGER: ['e', 'n', 'l', 'g', 'm', 'h'],
    INT: ['e', 'n', 'l', 'g', 'm', 'h'],
    STRING: ['e', 'n', 's', 'c', 'k', 'ib', 'inb', 'l', 'g', 'm', 'h', 'w'],
    TIME: ['e', 'n', 'l', 'g', 'm', 'h'],
    ADDRESS: ['w', 'y'],
    ADDRESSCOUNTRY: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    ADDRESSSTATE: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    AUTONUMBER: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    BIRTHDAY: ['e', 'n', 'l', 'g', 'm', 'h'],
    BITVECTOR: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    CONTENT: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    CURRENCY: ['e', 'n', 'l', 'g', 'm', 'h'],
    CURRENCYCODE: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    DATACATEGORYGROUPREFERENCE: ['e', 'n'],
    DATEONLY: ['e', 'n', 'l', 'g', 'm', 'h'],
    DIVISION: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    DUEDATE: ['e', 'n', 'l', 'g', 'm', 'h'],
    DYNAMICENUM: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    EMAIL: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    ENCRYPTEDTEXT: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    ENTITYID: ['e', 'n', 's'],
    ENUMORID: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    EXTERNALID: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    FAX: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    HTMLMULTILINETEXT: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    HTMLSTRINGPLUSCLOB: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    INETADDRESS: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    LOCATION: ['w', 'y'],
    MULTIENUM: ['e', 'n', 'i', 'x'],
    MULTILINETEXT: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    PERCENT: ['e', 'n', 'l', 'g', 'm', 'h'],
    PHONE: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    RECORDTYPE: ['e', 'n'],
    SFDCENCRYPTEDTEXT: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    SIMPLENAMESPACE: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    STATICENUM: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    STRINGPLUSCLOB: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    TEXTENUM: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'],
    TIMEONLY: ['e', 'n', 'l', 'g', 'm', 'h'],
    URL: ['e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i']
};

export const lightningBoxTypes = {
    DATE: 'date',
    DATETIME: 'datetime',
    NUMBER: 'number',
    CHECKBOX: 'checkbox',
    TEXT: 'text'
};