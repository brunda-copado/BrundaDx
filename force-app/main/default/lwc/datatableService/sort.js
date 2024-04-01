const ASC = 'asc';

// PUBLIC

export function sortRows(columns, data, field) {
    if (!data || !columns) return;
    const col = columns.find((column) => column.fieldName === field.name && column.sortable);
    if (col) {
        const cloneData = [...data];
        return cloneData.sort(_sortBy(field.name.replace('LinkName', 'Name'), field.sortDirection === ASC ? 1 : -1));
    } else {
        return;
    }
}

// PRIVATE

/**
 * NOTE: Special characters like á are understood as greater than z
 */
function _sortBy(field, reverse) {
    const key = (x) => x[field];

    return (a, b) => {
        a = key(a) || '';
        b = key(b) || '';

        if (a && isNaN(a)) {
            a = a.toLowerCase();
        }
        if (b && isNaN(b)) {
            b = b.toLowerCase();
        }

        return reverse * ((a > b) - (b > a));
    };
}