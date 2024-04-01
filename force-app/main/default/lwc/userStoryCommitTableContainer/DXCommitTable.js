import { label, schema } from './constants';

import TIME_ZONE from '@salesforce/i18n/timeZone';

const ADD_OPERATION_OPTION = { label: label.ADD, value: 'Add' };
const DELETE_OPERATION_OPTION = { label: label.DELETE, value: 'Delete' };
const FULL_OPERATION_OPTION = { label: 'Full', value: 'Full' };
const RETRIEVE_ONLY_OPERATION_OPTION = { label: label.RETRIEVE_ONLY, value: 'RetrieveOnly' };

export class DXCommitTable {
    getRowId(userStoryId, row) {
        return userStoryId + ';' + row.Directory + ';' + row.MemberType + ';' + row.MemberName;
    }

    parseUserStoryMetadata(records) {
        return records.map((record) => {
            const apiName = record[schema.METADATA_API_NAME_FIELD.fieldApiName];
            const type = record[schema.METADATA_TYPE_FIELD.fieldApiName];
            const action = record[schema.METADATA_ACTION_FIELD.fieldApiName];
            const directory = record[schema.METADATA_DIRECTORY_FIELD.fieldApiName];
            const category = record[schema.METADATA_CATEGORY_FIELD.fieldApiName];
            const lastModifiedDate = record.LastModifiedDate;
            const lastModifiedBy = record.LastModifiedBy;
            const jsonInformation = record[schema.JSON_INFORMATION_FIELD.fieldApiName];

            return {
                MemberName: apiName,
                MemberType: type,
                Directory: directory,
                LastModifiedDate: lastModifiedDate,
                LastModifiedByName: lastModifiedBy ? lastModifiedBy.Name : '',
                Operation: action,
                Category: category,
                OtherInformation: jsonInformation
            };
        });
    }

    createSelectedResult(row) {
        return {
            a: row.Operation,
            c: row.Category,
            m: row.Directory,
            n: row.MemberName,
            t: row.MemberType,
            j: row.OtherInformation
        };
    }

    getColumns() {
        return [
            {
                label: label.OPERATION,
                fieldName: 'Operation',
                type: 'operation',
                typeAttributes: {
                    rowId: { fieldName: 'Id' },
                    options: { fieldName: 'OperationOptions' },
                    readOnlyMode: { fieldName: 'ReadOnlyMode' },
                    selectedCount: { fieldName: 'SelectedCount' }
                },
                searchable: true,
                sortable: true,
                filterable: true,
                filtertype: 'multi-select',
                filterOperation: 'equals',
                initialWidth: 160,
                wrapText: true
            },
            { label: label.NAME, fieldName: 'MemberName', type: 'text', searchable: true, sortable: true, filterable: true, filtertype: 'input' },
            {
                label: label.TYPE,
                fieldName: 'MemberType',
                type: 'text',
                searchable: true,
                sortable: true,
                filterable: true,
                filtertype: 'multi-select',
                filterOperation: 'equals',
                initialWidth: 150
            },
            {
                label: label.DIRECTORY,
                fieldName: 'Directory',
                type: 'text',
                searchable: true,
                sortable: true,
                filterable: true,
                filtertype: 'input',
                editable: true,
                initialWidth: 320
            },
            {
                label: label.LAST_MODIFIED_DATE,
                fieldName: 'LastModifiedDate',
                type: 'date',
                searchable: false,
                sortable: true,
                filterable: true,
                filtertype: 'range',
                initialWidth: 200,
                typeAttributes: {
                    day: '2-digit',
                    month: 'short',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    timeZone: TIME_ZONE
                }
            },
            {
                label: label.LAST_MODIFIED_BY,
                fieldName: 'LastModifiedByName',
                type: 'text',
                searchable: true,
                sortable: true,
                filterable: true,
                filtertype: 'input',
                initialWidth: 200
            }
        ];
    }

    getDefaultSortedByFieldName() {
        return 'LastModifiedDate';
    }

    getOperationOptions(row) {
        let operations = [ADD_OPERATION_OPTION, DELETE_OPERATION_OPTION];
        switch (row.MemberType) {
            case 'Profile':
            case 'PermissionSet':
            case 'MutingPermissionSet':
            case 'CustomObject':
                operations.push(FULL_OPERATION_OPTION);
                break;
            default:
                break;
        }
        operations.push(RETRIEVE_ONLY_OPERATION_OPTION);
        return operations;
    }
}