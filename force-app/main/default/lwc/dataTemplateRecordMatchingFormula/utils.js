export function prepareFieldsForCombobox(fields) {
    return fields.map((field) => {
        return { label: `${field.label} (${field.name})`, value: field.name };
    });
}

export function adjustFieldsWithReference(field) {
    const adjustedValues = {};
    let fields;
    if (field && field.includes('.')) {
        fields = field.split('.');
        adjustedValues.primary = `${fields[0]}Id`;
        adjustedValues.secondary = fields[1];
    } else if (field && field.includes('__r')) {
        fields = field.split('__r');
        adjustedValues.primary = `${fields[0]}__c`;
        adjustedValues.secondary = fields[1];
    } else {
        adjustedValues.primary = field;
    }
    return adjustedValues;
}

export function adjustReference(field, parentField) {
    if (field.includes('Id')) {
        return field.replace('Id', `.${parentField}`);
    } else {
        return field.replace('__c', `__r.${parentField}`);
    }
}

export function getFieldLabelFromSelectOptions(field, selectOptions) {
    if(field && selectOptions){
        const selectOption = selectOptions.find(option => option.value === field);
        return  selectOption ? selectOption.label : '';
    }
}