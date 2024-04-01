const AVAILABLE_FILTER_TYPE = ['input', 'range', 'boolean', 'list', 'text', 'multi-select'];
const VALIDATE_EVENT = 'validate';
const INCLUDES = 'includes';
const EQUALS = 'equals';
const LABEL_STACKED = 'label-stacked';
const TYPE_TEXT = 'text';
const TYPE_INPUT = 'input';
const TYPE_LIST = 'list';
const TYPE_RANGE = 'range';
const TYPE_CHECKBOX = 'checkbox';
const TYPE_DATE = 'date';
const TYPE_ARRAY = 'multi-select';
const TYPE_CONVERSION = new Map([
    ['boolean', 'checkbox'],
    ['date-local', 'date'],
    ['phone', 'tel'],
    ['currency', 'text'],
    ['percent', 'text']
]);

import MIN from '@salesforce/label/c.MinFilterRange';
import MAX from '@salesforce/label/c.MaxFilterRange';
import FROM from '@salesforce/label/c.FromFilterRange';
import TO from '@salesforce/label/c.ToFilterRange';

export const constants = {
    AVAILABLE_FILTER_TYPE,
    VALIDATE_EVENT,
    INCLUDES,
    EQUALS,
    LABEL_STACKED,
    TYPE_TEXT,
    TYPE_INPUT,
    TYPE_LIST,
    TYPE_RANGE,
    TYPE_CHECKBOX,
    TYPE_ARRAY,
    TYPE_CONVERSION,
    TYPE_DATE
};

export const label = {
    MIN,
    MAX,
    FROM,
    TO
};