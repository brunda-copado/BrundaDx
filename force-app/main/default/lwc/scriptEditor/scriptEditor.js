import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import CODEMIRROR from '@salesforce/resourceUrl/CodeMirrorLibrary';
import CODEMIRROR_URL_VARIABLES from 'c/codeMirrorVariables';

import SCRIPT from '@salesforce/schema/Function__c.Script__c';

import EDIT from '@salesforce/label/c.EDIT';
import CANCEL from '@salesforce/label/c.Cancel';
import SAVE from '@salesforce/label/c.Save';
import ERROR from '@salesforce/label/c.ERROR';
import SUCCESS from '@salesforce/label/c.SUCCESS';
import SCRIPT_UPDATED from '@salesforce/label/c.Script_Updated';
import ERROR_INITIALIZING_SCRIPT_EDITOR from '@salesforce/label/c.Error_Initializing_Script_Editor';
import LOADING from '@salesforce/label/c.LOADING';

const FIELDS = [SCRIPT];

export default class ScriptEditor extends LightningElement {
    label = {
        EDIT,
        CANCEL,
        SAVE,
        LOADING
    };

    @api recordId;

    loading = true;
    readOnly;
    editMode = false;
    function;
    editor;

    _script;

    @wire(getObjectInfo, { objectApiName: SCRIPT.objectApiName })
    wiredInfo({ error, data }) {
        if (error) {
            this.showToast(ERROR, error.body.message);
        } else if (data) {
            const field = data.fields[SCRIPT.fieldApiName];
            this.readOnly = !field.updateable;
            this.label.SCRIPT_LABEL = data.fields[SCRIPT.fieldApiName].label;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            this.showToast(ERROR, error.body.message);
        } else if (data) {
            this.function = data;
            this.script = this.function.fields[SCRIPT.fieldApiName].value;
        }
    }

    async connectedCallback() {
        try {
            await this.loadResources();
            this.initEditor();
            this.script = this._script;
        } catch (error) {
            this.showToast(ERROR_INITIALIZING_SCRIPT_EDITOR, error.body.message);
        }
        this.loading = false;
    }

    get script() {
        return this._script;
    }

    set script(value) {
        this._script = value;
        if (this.script) {
            this.editor?.getDoc()?.setValue(this.script);
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.editor?.refresh(), 1);
        }
    }

    async loadResources() {
        await loadScript(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.codemirrorJS);
        await loadScript(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.lintJS);
        await loadScript(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.shellJS);
        await loadStyle(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.codemirrorCSS);
        await loadStyle(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.lintCSS);
    }

    renderedCallback() {
        if (this.editMode) {
            this.moveScriptContainerToModalContainer();
        }
    }

    textArea() {
        const result = document.createElement('textarea');
        result.classList.add('script');
        this.template.querySelector('.script-container').appendChild(result);
        return result;
    }

    initEditor() {
        // eslint-disable-next-line no-undef
        this.editor = this.editor || CodeMirror.fromTextArea(this.textArea(), {
            lineNumbers: true,
            lineWrapping: true,
            mode: 'text/x-sh',
            readOnly: !this.editMode ? "nocursor" : "",
            gutters: ['CodeMirror-lint-markers'],
            lint: true
        });
        this.editor.focus();
    }

    async save() {
        await this.quickSave();
        this.editMode = false;
        this.editor.setOption("readOnly", "nocursor");
        this.moveScriptContainerToMainContainer();
    }

    async quickSave() {
        this.loading = true;

        try {
            await updateRecord(this.record());
            this.showToast(SUCCESS, SCRIPT_UPDATED, 'success');
        } catch (error) {
            this.showToast(ERROR, error.body.message);
        }

        this.loading = false;
    }

    edit() {
        this.editMode = true;
        this.editor.setOption("readOnly", "");
    }

    cancel() {
        this.editMode = false;
        this.editor.setOption("readOnly", "nocursor");
        this.editor?.getDoc()?.setValue(this.script ? this.script : "");
        this.moveScriptContainerToMainContainer();
    }

    record() {
        return {
            fields: {
                Id: this.function.id,
                [SCRIPT.fieldApiName]: this.editor.getValue()
            }
        };
    }

    showToast(title, message, variant = 'error') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    moveScriptContainerToMainContainer() {
        this.template.querySelector('.main-container').appendChild(this.template.querySelector('.script-container'));
    }

    moveScriptContainerToModalContainer() {
        this.template.querySelector('.modal-container').appendChild(this.template.querySelector('.script-container'));
    }
}