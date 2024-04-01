import { showToastError } from 'c/copadocoreToastNotification';

import User_Story__c from '@salesforce/schema/User_Story__c';

import Complete_All_Fields from '@salesforce/label/c.Complete_All_Fields';

// TODO: Move validation functions to other file ( validation )

const versionDownloadURL = '/sfc/servlet.shepherd/version/download/';
const documentDownloadURL = '/sfc/servlet.shepherd/document/download/';
const stepEventURI = '/events/copado/v1/step-monitor/';
const usApiName = User_Story__c.objectApiName;
const namespace = usApiName.slice(0, usApiName.indexOf('User_Story__c'));
const namespaceClass = namespace.replace('__', '.');

/**
 * Automated form validation. Receives the component template (this.template), the context (this) and an optional object with options:
 *
 * Call example:
 *           utils.formValidation(this.template, this);
 *
 *           utils.formValidation(this.template, this, options);
 *
 *           options: {
 *               validationClass: 'myValidatorClass',
 *               validationMessage: 'my error message'
 *           }
 *
 * Returns true or false depending if the form is valid or not and triggers an error toast notification.
 */

const autoFormValidation = (form, context, options) => {
    if (!form || typeof form !== 'object') {
        console.error('Form validation. Template component is missed in validation');
        return false;
    }

    if (!context || typeof context !== 'object') {
        console.error('Form validation. Context is missed in validation');
        return false;
    }

    const validationClass = options && options.validationClass ? `.${options.validationClass}` : '.validValue';
    const validationMessage = options && options.validationMessage ? options.validationMessage : Complete_All_Fields;
    const formFields = form.querySelectorAll(validationClass);
    formFields.forEach(field => {
        field.value = field.value ? field.value.trim() : field.value;
    });

    const allValid = [...form.querySelectorAll(validationClass)].reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
    }, true);

    const toastOptions = {
        message: validationMessage
    };

    if (!allValid) {
        showToastError(context, toastOptions);
    }

    return allValid ? true : false;
};

/**
 * Form validation. Receives the component template (this.template) and optionally the class used
 * for required form fields ( validValue as default)
 *
 * Call example:
 *           utils.formValidation(this.template);
 *           utils.formValidation(this.template, 'myValidatorClass');
 *
 * Returns true or false depending if the form is valid or not.
 */

const formValidation = (form, validClass) => {
    if (!form || typeof form !== 'object') {
        console.error('Form validation. Template component is missed in validation');
        return false;
    }

    const validationClass = validClass ? `.${validClass}` : '.validValue';
    const formFields = form.querySelectorAll(validationClass);
    formFields.forEach(field => {
        field.value = field.value ? field.value.trim() : field.value;
    });
    const allValid = [...form.querySelectorAll(validationClass)].reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
    }, true);

    return allValid ? true : false;
};

/**
 * Checks if an object or array is empty.
 */
const isEmpty = object => {
    for (let key in object) {
        // eslint-disable-next-line no-prototype-builtins
        if (object.hasOwnProperty(key)) return false;
    }
    return true;
};

/**
 * Returns an array without duplicated values based on a propertyName.
 * @param {Array} array - Array or array of objects.
 * @param {string} propertyName - Property name to filter. If the array is simple don't send this parameter.
 */
const unique = (array, propertyName) => {
    let result;
    if (propertyName) {
        result = array.filter((e, i) => array.findIndex(a => a[propertyName] === e[propertyName]) === i);
    } else {
        result = array.filter((a, b) => array.indexOf(a) === b);
    }
    return result;
};

/**
 * Clones an object or array.
 * @param {*} data - Object or Array to clone.
 */
const cloneData = data => {
    return JSON.parse(JSON.stringify(data));
};

/**
 * Gets an unique key.
 * @param {string} key - name to start the key with.
 */
const uniqueKey = key => {
    return `${key}_` + Math.random().toString(36).substr(2, 9);
};

/**
 * Gets Month, day, hour format from a number of hours.
 * @param {number} hours - number of hours.
 */
const getMonthDayHourFormat = time => {
    time = parseFloat(time);
    let formatted = '';
    let hours = Math.round(time),
        days = 0,
        months = 0;

    days = (hours / 24) | 0;
    hours -= days * 24;

    months = (days / 30) | 0;
    days -= months * 30;

    hours = Math.round(hours * 100) / 100;

    if (months > 0) {
        formatted = `${months}M `;
    }
    if (days > 0) {
        formatted += `${days}d `;
    }
    if (hours > 0) {
        formatted += `${hours}h`;
    }

    if (months === 0 && days === 0 && hours === 0) {
        formatted = `${hours}h`;
    }

    return formatted;
};

/**
 * Returns an async function wrapped to handle its possible errors
 * @param {function} asyncFunction - Async function to wrap. It should return a promise
 * @param {object} onErrorOptions - Toast options for the error notification if function fails
 */
// TODO : pass context as an argument of the first function and use asyncFunction.call to avoid creating wrapper methods
const handleAsyncError =
    (asyncFunction, onErrorOptions) =>
    (context, ...params) =>
        asyncFunction(context, ...params).catch(error => {
            showToastError(
                context,
                Object.assign(onErrorOptions, {
                    message: error.body ? error.body.message : error.message
                })
            );
            console.error(error);
        });

/**
 * Returns a function ready to be executed after the provided delay if it has not been called again in the meantime
 * @param {function} functionToDebounce - Function that will wait before being executed
 * @param {object} delay - Time that the function should wait before being executed
 * @warning this method sets the "_timeout" variable available for usage in the context from which this function is called,
 *          so that the context can use the variable at its own discretion to, for example, call the clearTimeout() method
 */
const getDebouncedFunction =
    (functionToDebounce, delay) =>
    (context, ...params) => {
        clearTimeout(context._timeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        context._timeout = setTimeout(() => functionToDebounce.call(context, ...params), delay);
    };

/**
 * Returns an empty promise, so that when awaiting for its executions, other pending async operations in the call stack will be forced to be completed before this one.
 * Usage example: conditionally rendering an element in the template and flush salesforce async operations running under the hood to have access to the rendered element immediately
 */
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flushPromises = () => Promise.resolve();

// Explanation: https://stackoverflow.com/questions/990904/remove-accents-diacritics-in-a-string-in-javascript
const removeSpecialChars = str => str?.normalize('NFD').replace(/[\u0300-\u036f]/g, '');

/**
 * Reduces one or more LDS errors into a string of comma-separated error messages.
 * @param {FetchResponse|FetchResponse[]} errors
 * @return {String} Error messages separated by comma
 */
const reduceErrors = errors => {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }

    return (
        errors
            // Remove null/undefined items
            .filter(error => !!error)
            // Extract an error message
            .map(error => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map(e => e.message);
                }
                // Page level errors
                else if (error?.body?.pageErrors?.length) {
                    return error.body.pageErrors.map(e => e.message);
                }
                // Field level errors
                else if (error?.body?.fieldErrors?.length) {
                    const fieldErrors = [];
                    Object.values(error.body.fieldErrors).forEach(errorArray => {
                        fieldErrors.push(...errorArray.map(e => e.message));
                    });
                    return fieldErrors;
                }
                // UI API DML, object level errors
                else if (error?.body?.output?.errors?.length) {
                    return error.body.output.errors.map(e => e.message);
                }
                // UI API DML field level errors
                else if (error?.body?.output?.fieldErrors.length) {
                    const fieldErrors = [];
                    Object.values(error.body.output.fieldErrors).forEach(errorArray => {
                        fieldErrors.push(...errorArray.map(e => e.message));
                    });
                    return fieldErrors;
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // Unknown error shape so try HTTP status text
                return error.statusText;
            })
            // Flatten
            .reduce((prev, curr) => prev.concat(curr), [])
            // Remove empty strings
            .filter(message => !!message)
            .join()
    );
};

const formatLabel = (label, formattingArguments) => {
    return label.replace(/{(\d+)}/gm, (match, index) => (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
};

export {
    namespace,
    namespaceClass,
    stepEventURI,
    versionDownloadURL,
    documentDownloadURL,
    getDebouncedFunction,
    handleAsyncError,
    getMonthDayHourFormat,
    uniqueKey,
    cloneData,
    unique,
    isEmpty,
    formValidation,
    autoFormValidation,
    flushPromises,
    removeSpecialChars,
    reduceErrors,
    formatLabel
};