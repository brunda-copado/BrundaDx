export function validateInputs(inputs) {
    return inputs.reduce((validSoFar, inputField) => {
        return validSoFar && inputField.reportValidity();
    }, true);
}

export function formatLabel(customLabel, ...formattingArguments) {
    if (typeof customLabel !== 'string') return customLabel;
    return customLabel.replace(/{(\d+)}/gm, (match, index) => (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
}