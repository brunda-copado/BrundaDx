const adjustReference = (field) => field.includes('__r') ? field.replace('__r','__c') : field.concat('Id');

export const separatedFieldValue = ( value, isParent) => value && value.includes('.') ? isParent ? value.split('.')[1] : adjustReference(value.split('.')[0]) : isParent ? '' : value;