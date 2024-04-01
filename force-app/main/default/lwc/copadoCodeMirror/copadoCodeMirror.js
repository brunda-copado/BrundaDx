import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import { reduceErrors } from 'c/copadocoreUtils';
import { showToastError } from 'c/copadocoreToastNotification';

import CODEMIRROR from '@salesforce/resourceUrl/CodeMirrorLibrary';
import CODEMIRROR_URL_VARIABLES from 'c/codeMirrorVariables';

import ERROR_INITIALIZING_SCRIPT_EDITOR from '@salesforce/label/c.Error_Initializing_Script_Editor';

export default class CopadoCodeMirror extends LightningElement {
    editor;
    loading = true;
    _code;

    @api editMode = false;
    @api showLineNumber = false;
    @api wrapLine = false;
    @api textMode;
    @api
    get code() {
        return this._code;
    }
    set code(value) {
        this._code = value;
        this.editor?.getDoc()?.setValue(value);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => this.editor?.refresh(), 1);
    }

    async connectedCallback() {
        try {
            await this._loadResources();
            this._initCodeMirror();
        } catch (error) {
            showToastError(this, { title: ERROR_INITIALIZING_SCRIPT_EDITOR, message: reduceErrors(error) });
        }
        this.loading = false;
    }


    async _loadResources() {
        await loadScript(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.codemirrorJS);
        await loadScript(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.lintJS);
        await loadScript(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.shellJS);
        await loadStyle(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.codemirrorCSS);
        await loadStyle(this, CODEMIRROR + CODEMIRROR_URL_VARIABLES.lintCSS);
    }

    
    _initCodeMirror() {
        const textarea = document.createElement('textarea');
        this.template.querySelector('div').appendChild(textarea);

        // eslint-disable-next-line no-undef
        this.editor = CodeMirror.fromTextArea(textarea, {
            lineNumbers: this.showLineNumber,
            lineWrapping: this.wrapLine,
            mode: this.textMode,
            readOnly: !this.editMode,
            gutters: ['CodeMirror-lint-markers'],
            lint: true
        });

        if(this._code) {
            this.editor?.getDoc()?.setValue(this._code);
        }
    }
}