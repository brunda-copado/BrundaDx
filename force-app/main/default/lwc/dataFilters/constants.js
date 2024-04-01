import RESET_FILTERS from '@salesforce/label/c.Reset_Filters';
import FIELD from '@salesforce/label/c.Field';
import SELECT from '@salesforce/label/c.SELECT';
import OPERATOR from '@salesforce/label/c.Operator';
import DELETE from '@salesforce/label/c.DELETE';
import ADD_NEW_PARAMETER from '@salesforce/label/c.Add_new_parameter';
import FILTER_LOGIC from '@salesforce/label/c.Filter_Logic';
import DATA_TEMPLATE_INVALID_FILTERS from '@salesforce/label/c.DataTemplateInvalidFilters';
import DATA_TEMPLATE_FILTER_WARNING from '@salesforce/label/c.DataTemplateFilterWarning';
import DATA_FILTERS_RESOURCES from '@salesforce/resourceUrl/DataFiltersResources';

export const label = {
    RESET_FILTERS,
    FIELD,
    SELECT,
    OPERATOR,
    DELETE,
    ADD_NEW_PARAMETER,
    FILTER_LOGIC,
    DATA_TEMPLATE_INVALID_FILTERS,
    DATA_TEMPLATE_FILTER_WARNING
};

export const resource = {
    DATA_FILTERS_RESOURCES
};

export const dateOptions = [
    { value: 'YESTERDAY', label: 'Yesterday' },
    { value: 'TODAY', label: 'Today' },
    { value: 'TOMORROW', label: 'Tomorrow' },
    { value: 'LAST_WEEK', label: 'Last Week' },
    { value: 'THIS_WEEK', label: 'This Week' },
    { value: 'NEXT_WEEK', label: 'Next Week' },
    { value: 'LAST_MONTH', label: 'Last Month' },
    { value: 'THIS_MONTH', label: 'This Month' },
    { value: 'NEXT_MONTH', label: 'Next Month' },
    { value: 'LAST_N_DAYS:n', label: 'Last N Days' },
    { value: 'NEXT_N_DAYS:n', label: 'Next N Days' },
    { value: 'LAST_N_WEEKS:n', label: 'Last N Weeks' },
    { value: 'NEXT_N_WEEKS:n', label: 'Next N Weeks' },
    { value: 'THIS_QUARTER', label: 'This Quarter' },
    { value: 'LAST_QUARTER', label: 'Last Quarter' },
    { value: 'NEXT_QUARTER', label: 'Next Quarter' },
    { value: 'LAST_N_QUARTERS:n', label: 'Last N Quarters' },
    { value: 'NEXT_N_QUARTERS:n', label: 'Next N Quarters' },
    { value: 'THIS_YEAR', label: 'This Year' },
    { value: 'LAST_YEAR', label: 'Last Year' },
    { value: 'NEXT_YEAR', label: 'Next Year' },
    { value: 'LAST_N_YEARS:n', label: 'Last N Years' },
    { value: 'NEXT_N_YEARS:n', label: 'Next N Years' },
    { value: 'THIS_FISCAL_QUARTER', label: 'This Fiscal Quarter' },
    { value: 'LAST_FISCAL_QUARTER', label: 'Last Fiscal Quarter' },
    { value: 'NEXT_FISCAL_QUARTER', label: 'Next Fiscal Quarter' },
    { value: 'LAST_N_FISCAL_QUARTERS:n', label: 'Last N Fiscal Quarters' },
    { value: 'NEXT_N_FISCAL_QUARTERS:n', label: 'Next N Fiscal Quarters' },
    { value: 'THIS_FISCAL_YEAR', label: 'This Fiscal Year' },
    { value: 'LAST_FISCAL_YEAR', label: 'Last Fiscal Year' },
    { value: 'NEXT_FISCAL_YEAR', label: 'Next Fiscal Year' },
    { value: 'LAST_N_FISCAL_YEARS:n', label: 'Last N Fiscal Years' },
    { value: 'NEXT_N_FISCAL_YEARS:n', label: 'Next N Fiscal Years' },
    { value: 'customDate', label: 'Custom Date (Time)' }
];

export const datePeriods = [
    'YESTERDAY',
    'TODAY',
    'TOMORROW',
    'LAST_WEEK',
    'THIS_WEEK',
    'NEXT_WEEK',
    'LAST_MONTH',
    'THIS_MONTH',
    'NEXT_MONTH',
    'THIS_QUARTER',
    'LAST_QUARTER',
    'NEXT_QUARTER',
    'THIS_YEAR',
    'LAST_YEAR',
    'NEXT_YEAR',
    'THIS_FISCAL_QUARTER',
    'LAST_FISCAL_QUARTER',
    'NEXT_FISCAL_QUARTER',
    'THIS_FISCAL_YEAR',
    'LAST_FISCAL_YEAR',
    'NEXT_FISCAL_YEAR'
];

export const dateRanges = [
    'LAST_N_DAYS:n',
    'NEXT_N_DAYS:n',
    'LAST_N_WEEKS:n',
    'NEXT_N_WEEKS:n',
    'LAST_N_QUARTERS:n',
    'NEXT_N_QUARTERS:n',
    'LAST_N_YEARS:n',
    'NEXT_N_YEARS:n',
    'LAST_N_FISCAL_QUARTERS:n',
    'NEXT_N_FISCAL_QUARTERS:n',
    'LAST_N_FISCAL_YEARS:n',
    'NEXT_N_FISCAL_YEARS:n'
];

export const booleanOptions = [
    { value: 'TRUE', label: 'True' },
    { value: 'FALSE', label: 'False' }
];

export const customFilter = 'Custom Filter';
export const customFilterOption = { value: customFilter, label: customFilter };