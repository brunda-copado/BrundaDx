import { LightningElement, api } from 'lwc';

import { uniqueKey } from 'c/copadocoreUtils';

import Name from '@salesforce/label/c.NAME';
import Name_Placeholder from '@salesforce/label/c.Name_Placeholder';
import Value from '@salesforce/label/c.VALUE';
import Value_Placeholder from '@salesforce/label/c.Value_Placeholder';
import Required from '@salesforce/label/c.Required';
import DELETE from '@salesforce/label/c.DELETE';
import Add_new_parameter from '@salesforce/label/c.Add_new_parameter';

export default class ParameterEditor extends LightningElement {
    label = {
        Name,
        Name_Placeholder,
        Value,
        Value_Placeholder,
        Required,
        DELETE,
        Add_new_parameter
    };

    @api parameters;
    @api readOnly;
    @api editValuesOnly;
    @api canAddParameters;
    @api enableRequiredInput;

    get uniqueKey() {
        return uniqueKey("parameter");
    }

    get fullEditMode() {
        return !this.readOnly && !this.editValuesOnly;
    }

    get enableAddParameters() {
        return !this.readOnly && this.canAddParameters;
    }

    get hasParameters() {
        return this.parameterCount > 0;
    }

    @api get parameterCount() {
        return this.parameters.length;
    }

    handleChange(event) {
        const parameterId = event.target.dataset.id;
        const index = this.parameters.findIndex((parameter) => parameter.id === parameterId);

        this.dispatchEvent(new CustomEvent(this.eventName(event.target.name), {
            detail: {
                index: index,
                id: parameterId,
                name: event.target.name,
                value: this.getValue(event)
            }
        }));
    }

    eventName(name) {
        let result;

        if (name === "required") {
            result = "updaterequired";
        } else {
            result = "updateparameter";
        }

        return result;
    }

    getValue(event) {
        let result;

        if (event.target.name === "required") {
            result = event.target.checked;
        } else {
            result = event.detail.value;
        }

        return result;
    }

    handleAdd() {
        this.dispatchEvent(new CustomEvent("addparameter", {
            detail: {
                id: this.uniqueKey,
                name: "",
                value: ""
            }
        }));
    }

    handleDelete(event) {
        this.dispatchEvent(new CustomEvent("deleteparameter", {
            detail: event.target.dataset.id
        }));
    }
}