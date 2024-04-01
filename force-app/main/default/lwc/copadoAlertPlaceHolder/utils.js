import { VARIANT_ORDER } from './constants';

export function assignUUID(alert) {
    return {
        ...alert,
        id: getUUID()
    };
}

export function getUUID() {
    return 'alert' + Math.random().toString(36).substr(2, 9);
}

export function compareByVariant(alert1, alert2) {
    return VARIANT_ORDER.indexOf(alert1.variant) - VARIANT_ORDER.indexOf(alert2.variant);
}