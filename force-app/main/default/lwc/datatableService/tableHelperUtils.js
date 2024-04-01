import fetchColumnsConfiguration from '@salesforce/apex/DatatableServiceCtrl.fetchColumnsConfiguration';
import fetchData from '@salesforce/apex/DatatableServiceCtrl.fetchData';
import updateRecords from '@salesforce/apex/DatatableServiceCtrl.updateRecords';
import fetchRelatedListConfig from '@salesforce/apex/RelatedListCtrl.fetchRelatedListConfig';

export function columnsConfiguration(self, configuration) {
    return fetchColumnsConfiguration({ columnsConfiguration: configuration });
}

export function rowsData(self, queryConfiguration) {
    return fetchData({ queryConfiguration: queryConfiguration });
}

export function update(self, records) {
    return updateRecords(records);
}

export function relatedListConfiguration(self, queryConfiguration) {
    return fetchRelatedListConfig(queryConfiguration);
}