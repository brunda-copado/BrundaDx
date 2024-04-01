import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import CLOSE from '@salesforce/label/c.CLOSE';
import QUICK_FILTERS from '@salesforce/label/c.QuickFilters';
import CLEAR_ALL_FILTERS from '@salesforce/label/c.ClearAllFilters';

const FILTER_EVENT = 'filter';
const CLEAR_FILTER_EVENT = 'clearfilter';
const INCLUDES = 'includes';
const EQUALS = 'equals';

export const label = {
    CANCEL,
    SAVE,
    CLOSE,
    QUICK_FILTERS,
    CLEAR_ALL_FILTERS
};

export const constants = {
    FILTER_EVENT,
    CLEAR_FILTER_EVENT,
    INCLUDES,
    EQUALS
};