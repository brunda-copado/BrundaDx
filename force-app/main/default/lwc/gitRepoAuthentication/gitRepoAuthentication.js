import { LightningElement, track, api, wire } from 'lwc';
import createSSHKey from '@salesforce/apex/GitRepositoryController.createSSHKey';
import init from '@salesforce/apex/GitRepositoryController.init';
import getSSHKey from '@salesforce/apex/GitRepositoryController.getSSHKey';
import save from '@salesforce/apex/GitRepositoryController.save';
import { showToastSuccess, showToastError } from 'c/copadocoreToastNotification';
import gitRepoCommunicationChannel from '@salesforce/messageChannel/GitRepoCommunication__c';
import { publish, MessageContext } from 'lightning/messageService';
import SSH_URI_validation from '@salesforce/label/c.SSH_URI_validation';
import USERNAME from '@salesforce/label/c.USERNAME';
import PASSWORD from '@salesforce/label/c.PASSWORD';
import Please_Enter from '@salesforce/label/c.Please_Enter';
import AUTHENTICATION_SETTINGS from '@salesforce/label/c.AUTHENTICATION_SETTINGS';
import REPO_INFORMATION from '@salesforce/label/c.REPO_INFORMATION';
import PLEASE_AUTHENTICATE_REPO from '@salesforce/label/c.PLEASE_AUTHENTICATE_REPO';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import deleteSSHKey from '@salesforce/apex/GitRepositoryController.deleteSSHKey';
import AUTHENTICATION_TYPE_HELPTEXT from '@salesforce/label/c.AUTHENTICATION_TYPE_HELPTEXT';
import SSHKEY_HELPTEXT from '@salesforce/label/c.SSHKEY_HELPTEXT';
import AUTHENTICATION_TYPE from '@salesforce/label/c.AUTHENTICATION_TYPE';
import SSH_KEY from '@salesforce/label/c.SSH_KEY';
import SSH_KEY_DELETED from '@salesforce/label/c.SSH_KEY_DELETED';
import CONFIG_SAVED_SUCCESS from '@salesforce/label/c.CONFIG_SAVED_SUCCESS';

import { schema } from './constants';

const CONSTANT = {
    BRANCH_BASE_URL: 'https://{0}/(Username)/(RepositoryName)/{1}/',
    COMMIT_BASE_URL: 'https://{0}/(Username)/(RepositoryName)/commits/',
    PR_BASE_URL: 'https://{0}/(Username)/(RepositoryName)/',
    TAG_BASE_URL: 'https://{0}/(Username)/(RepositoryName)/{1}/',
    VS_BRANCH_BASE_URL: 'https://(Username).{0}/_git/(RepositoryName)/{1}/',
    VS_COMMIT_BASE_URL: 'https://(Username).{0}/_git/(RepositoryName)/',
    VS_PR_BASE_URL: 'https://(Username).{0}/_git/(RepositoryName)/',
    VS_TAG_BASE_URL: 'https://(Username).{0}/_git/(RepositoryName)/{1}/',
    GITHUB_COM: 'github.com',
    BITBUCKET_ORG: 'bitbucket.org',
    GITLAB_COM: 'gitlab.com',
    VISUALSTUDIO_COM: 'visualstudio.com',
    BITBUCKET_PROVIDER: 'Bitbucket',
    MTS_PROVIDER: 'Microsoft Team Service',
    CVC_PROVIDER: 'Copado Version Control',
    CVC_COM: '{Domain}.cvc.copado.com',
    KEYNAME: 'id_rsa.pub',
    SSH_STRING: 'SSH',
    HTTPS_STRING: 'HTTPS'
};
export default class GitRepoAuthentication extends LightningElement {
    _communicationId = 'gitRepoAuthenticationAlerts';
    _alertId = 'gitRepoAuthenticationAlertMessage';
    _attachmentId;

    @track httpsfieldVisible = false;
    @track showLoading = false;
    @track IsNewMode = true;
    @track httpsfieldVisibleViewMode = false;
    @track IsSSHKeyVisibleViewMode = false;
    @track fields;
    @api recordId;
    @api apiName;
    @api listViewApiName;
    @track sshKey;
    @track authType = 'SSH';
    @track errorMessage;
    @track hasError;
    @track uname;
    @track password;
    @track extraHeaders;
    @track unameReadOnly;
    @track passwordReadOnly;
    @track extraHeadersReadOnly;
    @track authTypeReadOnly;

    isSelected = false;
    label = {
        SSH_URI_validation,
        USERNAME,
        PASSWORD,
        Please_Enter,
        AUTHENTICATION_SETTINGS,
        REPO_INFORMATION,
        PLEASE_AUTHENTICATE_REPO,
        AUTHENTICATION_TYPE_HELPTEXT,
        SSHKEY_HELPTEXT,
        AUTHENTICATION_TYPE,
        SSH_KEY,
        SSH_KEY_DELETED,
        CONFIG_SAVED_SUCCESS
    };
    schema = schema;
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this._init();
    }

    _init() {
        this.showLoading = true;
        this.password = '';
        init({ repositoryId: this.recordId })
            .then(result => {
                console.log(JSON.stringify(result));
                this.showLoading = false;
                if (result) {
                    let repo = JSON.parse(result);
                    this.IsNewMode = false;
                    if (repo.authType === null) {
                        this.IsNewMode = true;
                    } else if (repo.authType === 'SSH') {
                        this.authType = 'SSH';
                        this.authTypeReadOnly = 'SSH';
                        this.sshKey = repo.sshKey.key;
                        this._attachmentId = repo.sshKey.attachmentId;
                        this.httpsfieldVisible = false;
                        this.httpsfieldVisibleViewMode = false;
                        this.isSelected = false;
                    } else {
                        this.authType = 'HTTPS';
                        this.authTypeReadOnly = 'HTTPS';
                        this.uname = repo.username;
                        this.unameReadOnly = repo.username;
                        this.extraHeaders = repo.headers;
                        this.httpsfieldVisible = true;
                        this.httpsfieldVisibleViewMode = true;
                    }
                }
            })
            .catch(error => {
                this.showLoading = false;
                this.errorMessage = error;
            });
    }
    //Modal Handling for Mode=New
    openAuthenticateModal() {
        this._showModal();
    }
    closeModal() {
        this._hideModal();
    }
    authenticateDetails(e) {
        if (this.validateFields() && this.validateHttpsFields()) {
            this.showLoading = true;
            const inputFields = e.detail.fields;
            this.showLoading = true;
            this.template.querySelector('lightning-record-edit-form').submit(inputFields);
            save({
                repositoryId: this.recordId,
                authType: this.authType,
                username: this.uname,
                password: this.password,
                extraHeaders: this.extraHeaders
            })
                .then(() => {
                    this.showLoading = false;
                    this.showLoading = false;
                    this.IsNewMode = false;
                    this._hideModal();
                    this.hasError = false;
                    this.IsSSHKeyVisibleViewMode = this.authType === 'HTTPS';
                    showToastSuccess(this, { message: this.label.CONFIG_SAVED_SUCCESS });
                    publish(this.messageContext, gitRepoCommunicationChannel, { isAuthenticated: true });
                    this._init();
                    this.closeModal();
                })
                .catch(error => {
                    publish(this.messageContext, gitRepoCommunicationChannel, { isAuthenticated: false });
                    showToastError(this, { message: error.detail });
                    this.showLoading = false;
                    this.IsNewMode = false;
                    this._hideModal();
                    this._init();
                    this.closeModal();
                });
        }
    }

    get authenticationTypeOptions() {
        return [
            { label: 'SSH', value: 'SSH' },
            { label: 'HTTPS', value: 'HTTPS' }
        ];
    }
    handleauthTypeChange(event) {
        const selectedOption = event.detail.value;
        this.authType = selectedOption;
        if (selectedOption === 'HTTPS') {
            //this.httpsfieldVisibleViewMode = true;
            this.httpsfieldVisible = true;
        } else {
            //this.httpsfieldVisibleViewMode = false;
            this.uname = '';
            this.password = '';
            this.httpsfieldVisible = false;
        }
    }
    handleUnameChange(e) {
        this.uname = e.target.value;
    }
    handlePasswordChange(e) {
        this.password = e.target.value;
    }
    handleHeaderChange(e) {
        this.extraHeaders = e.target.value;
    }
    keytoggleHandler() {
        this.isSelected = !this.isSelected;
        this.IsSSHKeyVisibleViewMode = !this.IsSSHKeyVisibleViewMode;
    }
    //Modal Handling for Mode = Edit
    editAuthenticateModal() {
        this._showModal();
    }
    closeAuthenticateModal() {
        this._hideModal();
    }
    editAuthenticateDetails() {
        this.showLoading = true;
    }
    validateFields() {
        return [...this.template.querySelectorAll('lightning-input-field')].reduce((validSoFar, field) => {
            return validSoFar && field.reportValidity();
        }, true);
    }

    validateHttpsFields() {
        let uri = this.template.querySelector('lightning-input-field[data-name="URI__c"]').value;
        if (
            (this.authType === CONSTANT.SSH_STRING && uri.startsWith('https')) ||
            (this.authType === CONSTANT.HTTPS_STRING && !uri.startsWith('https'))
        ) {
            this.hasError = true;
            this.errorMessage = this.label.SSH_URI_validation;
            return false;
        }
        if (this.authType === CONSTANT.HTTPS_STRING) {
            if (!this.uname || this.uname === '') {
                this.hasError = true;
                this.errorMessage = this.label.Please_Enter + ' ' + this.label.USERNAME;
                return false;
            }
            if (!this.password || this.password === '') {
                this.hasError = true;
                this.errorMessage = this.label.Please_Enter + ' ' + this.label.PASSWORD;
                return false;
            }
        }
        return true;
    }

    handleError(e) {
        showToastError(this, { message: e });
    }

    createSSHKey() {
        this.showLoading = true;
        createSSHKey({ repositoryId: this.recordId })
            .then(result => {
                if (JSON.parse(result).ok) {
                    getSSHKey({ repositoryId: this.recordId })
                        .then(val => {
                            this.sshKey = JSON.parse(val).key;
                            this._attachmentId = JSON.parse(val).attachmentId;
                            this.showLoading = false;
                            publish(this.messageContext, gitRepoCommunicationChannel, { isAuthenticated: true });
                        })
                        .catch(error => {
                            this.showLoading = false;
                            console.error(error);
                            this.handleError(error.body.message);
                        });
                }
            })
            .catch(error => {
                this.showLoading = false;
                this.handleError(error.body.message);
                console.error(error.body.message);
            });
    }

    /**
     * Bitbucket SSH: git clone git@bitbucket.org:ztugcesirin/copado-poc.git
     * Bitbucket HTTPS: git clone https://ztugcesirin@bitbucket.org/ztugcesirin/copado-poc.git
     * Gitlab SSH: git@gitlab.com:username/reponame.git
     * Gitlab HTTPS: https://gitlab.copado.com/app-dev/copado_dev.git
     * Github SSH:  git@github.com:tugce/TestPrivateRepo.git
     * Github HTTPS:  https://github.com/tugce/TestPrivateRepo.git
     * VSTS SSH:
     * VSTS HTTPS:
     * */
    populateURLFields(event) {
        let gitProvider = event.detail.value;
        let commitBaseUrl = this.template.querySelector('lightning-input-field[data-name="commitBaseURL"]');
        let branchBaseUrl = this.template.querySelector('lightning-input-field[data-name="branchBaseURL"]');
        let pullRequestBaseUrl = this.template.querySelector('lightning-input-field[data-name="pullRequestBaseURL"]');
        let tagBaseUrl = this.template.querySelector('lightning-input-field[data-name="tagBaseURL"]');

        if (gitProvider && gitProvider !== 'Others') {
            let branchBaseParameter =
                gitProvider === CONSTANT.BITBUCKET_PROVIDER ? 'branch' : gitProvider === CONSTANT.CVC_PROVIDER ? 'src/branch' : 'tree';
            let tagBaseParameter = gitProvider === CONSTANT.BITBUCKET_PROVIDER ? 'src' : gitProvider === CONSTANT.CVC_PROVIDER ? 'src/tag' : 'tags';
            let branchBaseURLProvider = gitProvider === CONSTANT.MTS_PROVIDER ? CONSTANT.VS_BRANCH_BASE_URL : CONSTANT.BRANCH_BASE_URL;
            let commitBaseURLProvider = gitProvider === CONSTANT.MTS_PROVIDER ? CONSTANT.VS_COMMIT_BASE_URL : CONSTANT.COMMIT_BASE_URL;
            let prBaseURLProvider = gitProvider === CONSTANT.MTS_PROVIDER ? CONSTANT.VS_PR_BASE_URL : CONSTANT.PR_BASE_URL;
            let tagBaseURLProvider = gitProvider === CONSTANT.MTS_PROVIDER ? CONSTANT.VS_TAG_BASE_URL : CONSTANT.TAG_BASE_URL;
            let selectedProvider =
                gitProvider === 'Github'
                    ? CONSTANT.GITHUB_COM
                    : gitProvider === CONSTANT.BITBUCKET_PROVIDER
                    ? CONSTANT.BITBUCKET_ORG
                    : gitProvider === CONSTANT.CVC_PROVIDER
                    ? CONSTANT.CVC_COM
                    : gitProvider === 'GitLab'
                    ? CONSTANT.GITLAB_COM
                    : gitProvider === CONSTANT.MTS_PROVIDER
                    ? CONSTANT.VISUALSTUDIO_COM
                    : '';

            // Branch base url
            branchBaseUrl.value = this.formatString(branchBaseURLProvider, selectedProvider, branchBaseParameter);
            branchBaseUrl.value = branchBaseUrl.value.replace('(', '{').replace(')', '}');

            // Commit base url
            commitBaseUrl.value = this.formatString(commitBaseURLProvider, selectedProvider);
            commitBaseUrl.value = commitBaseUrl.value.replace('(', '{').replace(')', '}');

            // Pr base url
            pullRequestBaseUrl.value = this.formatString(prBaseURLProvider, selectedProvider);
            pullRequestBaseUrl.value = pullRequestBaseUrl.value.replace('(', '{').replace(')', '}');

            // Tag base url
            tagBaseUrl.value = this.formatString(tagBaseURLProvider, selectedProvider, tagBaseParameter);
            tagBaseUrl.value = tagBaseUrl.value.replace('(', '{').replace(')', '}');
        } else {
            branchBaseUrl.value = null;
            commitBaseUrl.value = null;
            pullRequestBaseUrl.value = null;
            tagBaseUrl.value = null;
        }
    }

    formatString(format, ...values) {
        return format.replace(/{(\d+)}/g, (match, index) => {
            return typeof values[index] !== 'undefined' ? values[index] : match;
        });
    }

    copyToClipboard() {
        if (navigator.clipboard && window.isSecureContext) {
            return navigator.clipboard.writeText(this.sshKey);
        } else {
            let textArea = document.createElement('textarea');
            textArea.value = this.sshKey;
            textArea.style.position = 'fixed';
            textArea.style.left = '-999999px';
            textArea.style.top = '-999999px';
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();
            if (document.execCommand('copy')) {
                textArea.remove();
            }
        }
    }

    _showModal() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    _hideModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    _showAlert(error) {
        const alert = {
            operation: 'add',
            message: error,
            dismissible: true,
            variant: 'error',
            communicationId: this._communicationId,
            id: this._alertId
        };
        publish(this._context, COPADO_ALERT_CHANNEL, alert);
    }

    _clearAlert() {
        const alert = {
            operation: 'remove',
            communicationId: this._communicationId,
            id: this._alertId
        };
        publish(this._context, COPADO_ALERT_CHANNEL, alert);
    }

    async handleDelete() {
        this.showLoading = true;
        if (this._attachmentId) {
            try {
                await deleteSSHKey({ attachmentId: this._attachmentId });
                this.showLoading = false;
                this.sshKey = '';
                this._attachmentId = null;
                showToastSuccess(this, { message: this.label.SSH_KEY_DELETED });
                publish(this.messageContext, gitRepoCommunicationChannel, { isAuthenticated: false });
            } catch (e) {
                this.showLoading = false;
                this._showAlert(e);
            }
        }
    }
}