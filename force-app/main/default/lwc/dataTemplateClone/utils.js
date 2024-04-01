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