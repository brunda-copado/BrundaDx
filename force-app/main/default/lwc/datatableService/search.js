import { searchableDataReducer } from './redux.js';
import { removeSpecialChars } from 'c/copadocoreUtils';

// PUBLIC

export const applySearch = async (columns, allRows, searchTerm) => {
    if (!allRows || !columns) return;
    const searchColumnConfig = _getSearchableColumns(columns);
    if (!searchColumnConfig) return;
    const data = searchableDataReducer(allRows, searchColumnConfig);
    if (!data) return;

    const _searchTerm = searchTerm ? (searchTerm + '').trim().toLowerCase() : '';

    if (_searchTerm === '') {
        return allRows;
    } else if (_searchTerm.length >= 2) {
        const rows = [];

        data.forEach((row, index) => {
            for (const field in row) {
                const col = searchColumnConfig.find((column) => column.fieldName === field);
                if (col) {
                    const urlLabelField = col?.typeAttributes?.label?.fieldName;
                    const matchUrlLabel = removeSpecialChars(row[urlLabelField]?.toLowerCase())?.includes(_searchTerm);
                    const matchFieldValue = !field.includes('LinkName') && removeSpecialChars((row[field] + '').toLowerCase())?.includes(_searchTerm);
                    if (matchUrlLabel || matchFieldValue) {
                        rows.push(row);
                        break;
                    }
                }
            }
        });
        const result = rows;
        return result;
    }
};

function _getSearchableColumns(columns) {
    const result = [];
    columns.forEach((column) => {
        if (column.searchable) {
            result.push(column);
        }
    });
    return result;
}