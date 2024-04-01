import fetchColumnsConfig from '@salesforce/apex/DynamicDatatableCtrl.fetchColumnsConfig';
import fetchData from '@salesforce/apex/EnvironmentVarPipelineRelatedListCtrl.fetchData';

//import fetchData from '@salesforce/apex/ManageEnvVarsExt.fetchData';

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function getColumnsConfig(self, columnsConfiguration) {
    return fetchColumnsConfig(columnsConfiguration);
}

/**
 * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
 */
export function getData(self, queryConfig) {
    return fetchData(queryConfig);
}