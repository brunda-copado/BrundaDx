import { label } from './constants';

export const compare = (a, b, c) => a.filter((ea) => !b.some((eb) => eb[c] === ea[c]));

export const generateMessages = (newFileds, removeFieds, newChilds, removedChilds, mainObject) => {
    const result = {};

    if (newFileds.length > 0 || newChilds.length > 0) {
        result.add = [];
    }

    if (removeFieds.length > 0 || removedChilds.length > 0) {
        result.remove = [];
    }

    newFileds.forEach((field) => {
        if (field.fieldType === 'reference') {
            result.add.push({ id: field.name, message: formatLabel(label.NEW_PARENT_OBJECT, Object.keys(field.parentObjectApiNameMap)[0]) });
        } else {
            result.add.push({ id: field.name, message: formatLabel(label.NEW_FIELD, field.name, mainObject) });
        }
    });

    newChilds.forEach((object) => {
        result.add.push({ id: object.childSObject, message: formatLabel(label.NEW_CHILD_OBJECT, object.childSObject) });
    });

    removeFieds.forEach((field) => {
        if (field.fieldType === 'reference') {
            result.remove.push({ id: field.name, message: formatLabel(label.REMOVE_PARENT_OBJECT, Object.keys(field.parentObjectApiNameMap)[0]) });
        } else {
            result.remove.push({ id: field.name, message: formatLabel(label.REMOVE_FIELD, field.name, mainObject) });
        }
    });

    removedChilds.forEach((object) => {
        result.remove.push({ id: object.childSObject, message: formatLabel(label.REMOVE_CHILD_OBJECT, object.childSObject) });
    });

    return result;
};

function formatLabel(customLabel, ...formattingArguments) {
    if (typeof customLabel !== 'string') return customLabel;
    return customLabel.replace(/{(\d+)}/gm, (match, index) => (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
}