import { LightningElement, wire } from 'lwc';

import { label } from './labels';
import dynamicExpressions from './dynamicExpressions';
import getApexExpressionOptions from '@salesforce/apex/DynamicExpressionHelperCtrl.getApexExpressionOptions';

export default class DynamicExpressionHelper extends LightningElement {
    label = label;

    selectedValues = [];
    classNames = [];

    value = 'inProgress';

    @wire(getApexExpressionOptions)
    wiredClassNames({ error, data }) {
        if (data) {
            this.classNames = data.map(option => ({ label: option, value: option }));

            this.classNames.push({
                value: '',
                label: label.APEX_CLASS,
                isFieldSelector: true,
                helpText: label.ApexClassHelpText
            });
        } else if (error) {
            console.error(error);
        }
    }

    get context() {
        return dynamicExpressions;
    }

    get parameter1() {
        const selectedContext = this.getSelectedOption(this.context.options, this.selectedValues[0]);
        return selectedContext || {};
    }

    get parameter2() {
        const selectedContext = this.getSelectedOption(this.parameter1.options, this.selectedValues[1]);
        if (selectedContext?.value === "Apex") {
            selectedContext.options = [...this.classNames];
        }
        return selectedContext || {};
    }

    get parameter3() {
        const selectedContext = this.getSelectedOption(this.parameter2.options, this.selectedValues[2]);
        return selectedContext || {};
    }

    get parameter4() {
        const selectedContext = this.getSelectedOption(this.parameter3.options, this.selectedValues[3]);
        return selectedContext || {};
    }

    get hasParameterOptions1() {
        return (this.parameter1?.options?.length && !this.parameter1.isFieldSelector);
    }

    get hasParameterOption2() {
        return (this.parameter2?.options?.length && !this.parameter2.isFieldSelector);
    }

    get hasParameterOption3() {
        return (this.parameter3?.options?.length && !this.parameter3.isFieldSelector);
    }

    get hasParameterOption4() {
        return (this.parameter4?.options?.length && !this.parameter4.isFieldSelector);
    }

    get selectedExpression() {
        const values = this.selectedValues.filter(value => !!value);
        return (values.length ? `{$${values.join('.')}}` : '');
    }

    handleChange(event) {
        const index = Number(event.target.getAttribute('data-index'));
        this.selectedValues[index] = event.detail.value;

        this.selectedValues = this.selectedValues.map((value, currentIndex) => {
            return currentIndex <= index ? value : null;
        });
    }

    copyToClipboard() {
        const element = this.template.querySelector("lightning-textarea");

        var hiddenInput = document.createElement("input");
        hiddenInput.setAttribute("value", element.value);

        document.body.appendChild(hiddenInput);
        hiddenInput.select();

        document.execCommand("copy");

        document.body.removeChild(hiddenInput);

        const button = this.template.querySelector("lightning-button");
        button.label = this.label.COPIED;
        button.iconName = "utility:check";

        setTimeout(() => {
            button.iconName = "utility:copy";
            button.label = this.label.COPY_TO_CLIPBOARD;
        }, 1500);
    }

    getSelectedOption(list, value) {
        return list?.filter(element => element.value === value)[0];
    }
}