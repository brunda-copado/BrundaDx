import NO_UPDATE from '@salesforce/label/c.NoUpdate';
import FORMULA from '@salesforce/label/c.Formula';
import SELECT from '@salesforce/label/c.SELECT';

export const label = {
    NO_UPDATE,
    FORMULA,
    SELECT
};

export const INPUT_TYPE_BY_FIELD_TYPE = {
    string: 'text',
    email: 'text',
    address: 'text',
    textarea: 'text',
    id: 'text',
    base64binary: 'text',
    url: 'text',
    phone: 'text',
    time: 'text',
    encryptedstring: 'text',
    picklist: 'text',
    multipicklist: 'text',
    time: 'text',
    date: 'date',
    datetime: 'datetime',
    integer: 'number',
    double: 'number',
    int: 'number',
    percent: 'number',
    currency: 'number',
    boolean: 'checkbox'
};

export const INPUT_FORMATTER_BY_FIELD_TYPE = {
    percent: 'percent-fixed',
    currency: 'currency'
};

export const REPLACE_PROPERTY_BY_FIELD_TYPE = {
    string: 'replaceValue',
    email: 'replaceValue',
    address: 'replaceValue',
    textarea: 'replaceValue',
    id: 'replaceValue',
    base64binary: 'replaceValue',
    url: 'replaceValue',
    phone: 'replaceValue',
    time: 'replaceValue',
    encryptedstring: 'replaceValue',
    picklist: 'replaceValue',
    multipicklist: 'replaceValue',
    date: 'replaceValueDate',
    datetime: 'replaceValueDatetime',
    integer: 'replaceValueNumber',
    double: 'replaceValueNumber',
    int: 'replaceValueNumber',
    percent: 'replaceValueNumber',
    currency: 'replaceValueNumber',
    boolean: 'replaceValue'
};

export const DEFAULT_VALUE_BY_FIELD_TYPE = {
    string: '',
    email: '',
    address: '',
    textarea: '',
    id: '',
    base64binary: '',
    url: '',
    phone: '',
    time: '',
    encryptedstring: '',
    picklist: '',
    multipicklist: '',
    date: null,
    datetime: null,
    integer: null,
    double: null,
    int: null,
    percent: null,
    currency: null,
    boolean: 'FALSE'
};

export const NO_UPDATE_OPTION = {
    label: NO_UPDATE,
    value: 'none'
};

export const BOOLEAN_OPTIONS = [
    { value: 'TRUE', label: 'True' },
    { value: 'FALSE', label: 'False' }
];