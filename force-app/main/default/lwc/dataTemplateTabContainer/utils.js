export function createAlert(message, variant, dismissible, communicationId, alertId, operation) {
    return {
        message: message,
        variant: variant,
        dismissible: dismissible,
        communicationId: communicationId,
        id: alertId,
        operation: operation
    };
}

export function formatLabel(customLabel, ...formattingArguments) {
    if (typeof customLabel !== 'string') return customLabel;
    return customLabel.replace(/{(\d+)}/gm, (match, index) => (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
}