import fetchColumnsConfig from '@salesforce/apex/DynamicDatatableCtrl.fetchColumnsConfig';
import fetchData from '@salesforce/apex/DynamicDatatableCtrl.fetchData';
import updateRecords from '@salesforce/apex/DynamicDatatableCtrl.updateRecords';

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function getColumnsConfig(self, columnsConfig) {
    return fetchColumnsConfig(columnsConfig);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function getRowsData(self, queryConfig) {
    return fetchData(queryConfig);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function update(self, records) {
    return updateRecords(records);
}

/**
 * NOTE: Special characters like á are understood as greater than z
 */
export function sortBy(field, reverse) {
    const key = (x) => x[field];

    return (a, b) => {
        a = key(a) || '';
        b = key(b) || '';
        return reverse * ((a > b) - (b > a));
    };
}