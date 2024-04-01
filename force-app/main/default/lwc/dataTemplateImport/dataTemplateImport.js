import { LightningElement, track, wire } from 'lwc';
import statics from '@salesforce/resourceUrl/Statics';
import { loadScript } from 'lightning/platformResourceLoader';
import { publish, MessageContext } from 'lightning/messageService';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';
import { reduceErrors } from 'c/copadocoreUtils';
import { createAlert } from 'c/datatemplateUtil';
import { createDataTemplateAttachmentsBody, updateRelationInAttchment, formatLabel, addNameSpace } from './utils';

import parseImportedFile from '@salesforce/apex/DataTemplateImportCtrl.parseImportedFile';
import fetchAddDescribeGlobalResults from '@salesforce/apex/DataTemplateImportCtrl.fetchAddDescribeGlobalResults';
import validateTemplateNameAndObject from '@salesforce/apex/DataTemplateImportCtrl.validateTemplateNameAndObject';
import fetchObjectFieldsDetail from '@salesforce/apex/DataTemplateImportCtrl.fetchObjectFieldsDetail';
import createDataTemplateAttachments from '@salesforce/apex/DataTemplateImportCtrl.createDataTemplateAttachments';
import updateTemplateDetailAttachment from '@salesforce/apex/DataTemplateImportCtrl.updateTemplateDetailAttachment'; 
import createDataTemplate from '@salesforce/apex/DataTemplateImportCtrl.createDataTemplate';
import validateOrg from '@salesforce/apex/DataTemplateDefineDataSourceCtrl.validateOrg';
import getTemplateStaticResource from '@salesforce/apex/DataTemplateImportCtrl.getTemplateStaticResource';
import getNameSpace from '@salesforce/apex/DataTemplateImportCtrl.getNameSpace';


import { schema , label} from './constants';
export default class DataTemplateImport extends LightningElement {

    label = label;

    $copado;
    
    @track templateInformations;

    // alerts
    @wire(MessageContext)
    messageContext;
    

    _uploadedFiles;
    isLoading = false;
    sourceOrg;
    activateTemplate = false;
    globalDescribeResult;
    allSelectedTemplatesValid = false;
    allInvalid = false;
    validationInitiated = false;
    importInitiated =false;
    displayOptions = true;
    displayMainSection =false;
    displayFileUpload = false
    displayTemplateInformation = false;
    displayValidation = false;
    displayImport = false;
    hasError = false;
    validOrg = false;
    counter = 0;
    namespace
    communicationId = 'dataTemplateImport';

    get acceptedFormats() {
        return ['.json', '.zip'];
    }

    get disableValidation(){
        return this.isLoading || this.hasError || !this.validOrg ? true : !(this.sourceOrg && this.templateInformations.find( template => template.selected));
    }

    get disableImport(){
        return this.isLoading|| this.hasError ?  true :  this.allInvalid || !this.templateInformations.find( template => template.selected);
    }

    get infoAlert(){
        return this.validationInitiated ? this.allSelectedTemplatesValid ? this.label.ALL_TEMPLATES_VALID_MESSAGE : this.allInvalid ? this.label.ALL_TEMPLATES_INVALID_MESSAGE : this.label.SOME_TEMPLATES_INVALID_MESSAGE : this.label.TEMPLATE_VALIDATION_MESSAGE;
    }

    get counterInfo(){
        return this.validationInitiated && !this.importInitiated ? `${this.label.VALIDATED}: ${this.counter}/${this.totalTemplatesSelected}` : `${this.label.CREATED}: ${this.counter}/${this.totalTemplatesSelected}`;
    }

    get displayCounterBadge(){
        return this.isLoading && (this.validationInitiated || this.importInitiated);
    }

    get objectAPIName(){
        return addNameSpace(this.namespace, schema.DATA_TEMPLATE.objectApiName);
    }

    get activeFieldAPIName(){
        return addNameSpace(this.namespace, schema.ACTIVE.fieldApiName);
    }

    get sourceOrgFieldAPIName(){
        return addNameSpace(this.namespace, schema.SOURCE_ORG_FIELD.fieldApiName);
    }

    get totalTemplatesSelected(){
        return  this.templateInformations.reduce((total, element) => {
            let templateCount = 0;
            if(element.selected){
                templateCount = element.templates.length;
            }
            return total + templateCount;
        }, 0);
    }

    async connectedCallback(){
     try{
        this.namespace = await getNameSpace();
     }catch(error){
        this._displayError(error);
     }
      
    }

    renderedCallback(){
        loadScript(this, statics + '/js/libs/jquery.min.3.6.0.js')
        .then(() => {
            this.$copado = this.$copado || jQuery.noConflict();
        })
        .catch(error=>{
            console.error(error);
            this._displayError(error);
        });
        loadScript(this, statics + '/js/jszip.js');
    }

    handleUploadFinished(event) {
        try{
            this.isLoading = true;
            var uploadedFiles = [];
            let deferredArray = [];
            for(var i = 0; i < event.detail.files.length; i++){
                let deferredInnerArray = [];
                var resourcePointer = this.$copado;
                let deferred = new resourcePointer.Deferred();
                deferredArray.push( deferred );
                if(event.detail.files[i].type == 'application/zip'){
                    this._unzip_Decode(event.detail.files[i]).then(function(filesInFolder) {
                        for(var j = 0; j < Object.keys(filesInFolder[0].files).length; j++){
                            let innerDeferred = new resourcePointer.Deferred();
                            deferredInnerArray.push( innerDeferred );
                            var currentFile = filesInFolder[0].file(Object.keys(filesInFolder[0].files)[j]);
                            if(currentFile?.name.includes('.json') && !currentFile?.name.includes('__MACOSX')){
                                currentFile.async("string").then(function(data){
                                    uploadedFiles.push(data);
                                    innerDeferred.resolve();
                                });
                            } else {
                                innerDeferred.resolve();
                            }
                        }
                        resourcePointer.when.apply(this, deferredInnerArray).then(() => {
                            deferred.resolve();
                        });
                    })
                } else {
                    let fileReader = new FileReader();
                    fileReader.readAsText(event.detail.files[i]);
                    setTimeout(() => {
                        if (fileReader.result) {
                            uploadedFiles.push(fileReader.result);
                            deferred.resolve();
                        }
                    }, 100);
                }
            }
            this.$copado.when.apply(this, deferredArray).then(() => {
                this._parseImportedFiles(uploadedFiles);
            });
        }catch(error){
            this._displayError(error);
        }
    }

    handleChange(event){
        const templateNumber =  event.target.dataset.id;
        const isSelected = event.target.checked;
        this.templateInformations[templateNumber].selected = isSelected; 
    }

    handleCancel(){
        window.history.back();
    }

    handleActivation(event){
        try {
            this.activateTemplate = event.target.value;
        } catch (error) {
            console.error(error);
            this._displayError(error);
        }
    }

    async handleChangeSourceOrg(event) {
        try {
            this.isLoading = true
            this.sourceOrg = event.target.value;
            if(this.sourceOrg){
                this._clearAlerts();
                this.validOrg = await validateOrg({ orgId: this.sourceOrg });
                if(!this.validOrg){
                    const alertMessage = formatLabel(this.label.ORG_NOT_AUTHENTICATED, '/' + this.sourceOrg);
                    this._publishAlert(alertMessage, 'error', false);
                }
            }
            this.isLoading = false;
        } catch (error) {
            console.error(error);
            this._displayError(error);
            this.isLoading = false;
        }
    }

    async handleSelectImportOption(event){
        this.displayOptions = false;
        this.displayMainSection = true;
        const importOptionDetails = event.detail;
        if(importOptionDetails.option === 'file'){
            this.displayFileUpload = true;
        }else{
            this.isLoading = true;
            this.displayTemplateInformation = true;
            this.displayValidation = true;
            const provider = importOptionDetails.extension;
            await this._importFromStaticResource(provider);
            
        }
    }

    async handleValidation(event){
        try {
            this.isLoading = true;
            this.validationInitiated = true; 
            const globalDescribeResult = await fetchAddDescribeGlobalResults({orgId : this.sourceOrg});
            this.globalDescribeResult = JSON.parse(globalDescribeResult);
            await this._validateTemplates();
            this.displayValidation = false;
            this.displayImport = true;
        } catch (error) {
            this._displayError(error);
        }
        this.isLoading = false;
    }

    async handleImport(event){
        try {
            this.isLoading = true;
            this.counter = 0;
            this.importInitiated = true;
            const templateInformations = this.templateInformations;
            const importedTemplates = []
            for (const element of templateInformations) {
                if(element.selected){
                    const result = await this._processTemplates(element.templates);
                    importedTemplates.push(result);
                    this.counter = this.counter + result.length;
                }
            }
            this._publishAlert(this.label.FINAL_MESSAGE, 'success', false);
            this.displayFileUpload = false;
            this.displayTemplateInformation = false;
        } catch (error) {
            this._displayError(error);
        }
    }

    async _importFromStaticResource( provider){
        try{
            const staticResource = await getTemplateStaticResource ( { provider } );
            await this._unZipStaticResource(staticResource);
        } catch (error) {
            console.error(error);
            this._displayError(error);
        }
    }

    async _unZipStaticResource(staticResource){
        let uploadedFiles = [];
        const filesInFolder = await this._unzip_Decode(staticResource);
        for (const fileName of Object.keys(filesInFolder[0].files)) {
            const currentFile = filesInFolder[0].file(fileName);
            if (currentFile?.name.includes('.json') && !currentFile?.name.includes('__MACOSX')) {
                const data = await currentFile.async("string");
                uploadedFiles.push(data);
            }
        }
        this._parseImportedFiles(uploadedFiles);
    }

    async _parseImportedFiles(files){
        try{
            const parsedFiles = files.map(file => JSON.parse(file));
            this._uploadedFiles = parsedFiles;
            const result = await parseImportedFile({ jsonValue: files });
            const templateInformations = this._uploadedFiles.map( (element, index) => {
                return { 
                    groupNumber: index, 
                    mainTemplateName: element[0].values.dataTemplate.templateName,
                    mainTemplateInfo: `${element[0].values.dataTemplate.templateName} - ${element.length} ${label.TEMPLATE_CREATE}`, 
                    templates: element.map(template =>  {
                        template.values.relationListSize = template.values.relationList.length;
                        return template;
                    }), 
                    selected: true, 
                    disableSelection: false, 
                    displayValidationResult: false 
                } 
            });
            this.templateInformations = templateInformations;
            this.displayFileUpload = false;
            this.displayTemplateInformation = true;
            this.displayValidation = true;
        }catch(error){
            this._displayError(error);
        }
        this.isLoading = false;
    }

    async _processTemplates(templates){  
        const newDataTemplates = await this._createDataTemplates(templates);
        const newDataTemplatesValue = newDataTemplates.map(template => template.value);
        const updatedDataTemplates = await this._updateTemplateRelation(templates, newDataTemplatesValue);
        return updatedDataTemplates
    }

    async _updateTemplateRelation(templates, newDataTemplatesValue){
        const templateRelationUpdatePromises = [];
        for (const individualTemplate of templates) { 
            const newDataTemplateDetail = newDataTemplatesValue.find((dataTemplate) => {
                return dataTemplate.templateUUId === individualTemplate.templateUUId;
            });
            const individualTemplateRelationUpdatePromise = this._updateTemplateRelationInAttachment(individualTemplate, newDataTemplateDetail, newDataTemplatesValue);
            templateRelationUpdatePromises.push(individualTemplateRelationUpdatePromise);
        }
        return await Promise.allSettled(templateRelationUpdatePromises);
    }

    async _createDataTemplates(templates){
        const templateCreationPromises = [];
        for (const individualTemplate of templates) { 
            const individualTemplateCreationPromise = this._createTemplatesAndAttachments(individualTemplate);
            templateCreationPromises.push(individualTemplateCreationPromise);
        }
        return await Promise.allSettled(templateCreationPromises);
    }
    
    async _updateTemplateRelationInAttachment(individualTemplate, newDataTemplateDetail, settledTemplateValues){
        try{
            const dataObject = {
                importedObject : individualTemplate,
                newDataTemplateDetail : newDataTemplateDetail,
                realDataTemplateIdMap : settledTemplateValues
            };

            const updatedTemplateDetailsWithRelation = updateRelationInAttchment(dataObject);
            await updateTemplateDetailAttachment({dataTemplateId : newDataTemplateDetail.id, templateDetail : JSON.stringify(updatedTemplateDetailsWithRelation)});
            return newDataTemplateDetail.id;
        }
        catch(error){
            console.error(error);
            this._displayError(error);
            throw(error);
        }
    }

    async _createTemplatesAndAttachments(individualTemplate){
        try {
            const mainObject = individualTemplate.values.dataTemplate.templateMainObject
            const describeResult = await this._fetchFieldDetails(mainObject);
            const dataTemplateRecord = await this._createDataTemplate(individualTemplate);
            const configuredAttachments = this._configureAttachments(dataTemplateRecord, describeResult, individualTemplate);
            await this._createAttachments(configuredAttachments, dataTemplateRecord.id);
            const newTemplateDetail = {
                templateUUId: individualTemplate.templateUUId,
                id: dataTemplateRecord.id,
                name: dataTemplateRecord.Name,
                templateDetail: configuredAttachments.templateDetail
            };
            return newTemplateDetail;
        } catch(error){
            console.error(error);
            this._displayError(error); 
            throw(error);
        }
        
    }

    _configureAttachments(dataTemplateRecord, describeResult, individualTemplate){
        const configuredAttachments = {};
        const attachmentData = {
            parentId: dataTemplateRecord.id,
            templateDetails: dataTemplateRecord,
            describeResult: describeResult,
            globalDescribe: this.globalDescribeResult,
            sourceOrgId: this.sourceOrg,
            importedObj: individualTemplate.values
        }
        const attachmentsBody = createDataTemplateAttachmentsBody(attachmentData, this.namespace); 
        configuredAttachments.templateDetail = JSON.stringify(attachmentsBody.templateDetail);
        configuredAttachments.describeSobject = JSON.stringify(attachmentsBody.describeResult);

        return configuredAttachments;
    }

    async _createAttachments(configuredAttachments, dataTemplateId){
        await createDataTemplateAttachments ({ dataTemplateId , configuredAttachments : JSON.stringify(configuredAttachments) });
    }

    async _createDataTemplate(individualTemplate){
        const fields = {};
        const templateFieldsValues = individualTemplate.values.dataTemplate;
        fields[schema.NAME.fieldApiName] = templateFieldsValues.templateName;
        fields[addNameSpace(this.namespace, schema.ACTIVE.fieldApiName)] = this.activateTemplate;
        fields[addNameSpace(this.namespace, schema.MAIN_OBJECT.fieldApiName)] = templateFieldsValues.templateMainObject;
        fields[addNameSpace(this.namespace, schema.MAX_RECORD_LIMIT.fieldApiName)] = templateFieldsValues.templateQueryLimit;
        fields[addNameSpace(this.namespace, schema.DESCRIPTION.fieldApiName)] = templateFieldsValues.templateDescription;
        fields[addNameSpace(this.namespace, schema.FILTER_LOGIC.fieldApiName)] = templateFieldsValues.templateFilterLogic;
        fields[addNameSpace(this.namespace, schema.ATTACHMENT_OPTIONS.fieldApiName)] = templateFieldsValues.templateAttachmentOptions;
        fields[addNameSpace(this.namespace, schema.BATCH_SIZE.fieldApiName)] = templateFieldsValues.templateBatchSize;
        fields[addNameSpace(this.namespace, schema.MATCH_OWNERS.fieldApiName)] = templateFieldsValues.templateMatchOwners; 
        fields[addNameSpace(this.namespace, schema.MATCH_RECORDTYPE.fieldApiName)] = templateFieldsValues.templateMatchRecordTypes; 
        fields[addNameSpace(this.namespace, schema.CONTINUE_ON_ERROR.fieldApiName)] = templateFieldsValues.templateContinueOnError;
        fields[addNameSpace(this.namespace, schema.SOURCE_ORG_FIELD.fieldApiName)] = this.sourceOrg;
        fields.sobjectType =  addNameSpace(this.namespace, schema.DATA_TEMPLATE.objectApiName);
        const dataTemplate = await createDataTemplate({dataTemplate : fields});
        fields.id = dataTemplate.Id;
        return fields;
    }

    async _validateTemplates(){
        debugger;
        const finalValidationResult = await this._validateSelectedTemplates();
        this._processValidationResult(finalValidationResult);
    }

    async _validateSelectedTemplates() { 
        const finalValidationResult = [];
        const templateInformations = this.templateInformations;
        let result;
        for (const element of templateInformations) {
            if(element.selected){
                result = await this._validateTemplate(element.templates);
                this.counter = this.counter + result.length;
            }else{
                result = 'Not Selected';
            }
            finalValidationResult.push(result);
        }
        return finalValidationResult
    }

    async _validateTemplate(element){ 
        const validationPromises = [];
        for (const individualTemplate of element) { 
            const mainObject = individualTemplate.values.dataTemplate.templateMainObject;
            const templateName = individualTemplate.values.dataTemplate.templateName;
            const validationPromise = validateTemplateNameAndObject({ orgId: this.sourceOrg, mainObject : mainObject, templateName : templateName });
            validationPromises.push(validationPromise);
        }
        const settledValidationPromises = await Promise.allSettled(validationPromises);
        return settledValidationPromises;
    }

    _processValidationResult(finalValidationResult) {
        const templateInformations = this.templateInformations;
        const updatedTemplatesInformations = []; 
        let totalErrors = 0;
        let selectedTemplatesCount = 0; 
        let validatedTemplatesCount = 0; 
        for (var i = 0; i < finalValidationResult.length; i++) {
            const updatedTemplateInformation = []; 
            let allValid = false;
            let numberOfErrors = 0;
            let hasSystemError = false;
            let notSelected = false;
            if(finalValidationResult[i] === 'Not Selected'){
                updatedTemplateInformation.push(...templateInformations[i].templates.map(template => ({...template, isWarning : false, isCheck : false, isCross : false })));
                notSelected = true;
            }else{
                selectedTemplatesCount++; 
                for (var j = 0; j < finalValidationResult[i].length; j++) {
                    if(finalValidationResult[i][j].status === 'fulfilled'){
                        const result = JSON.parse(finalValidationResult[i][j].value);
                        numberOfErrors = result.duplicateName ? ++numberOfErrors : numberOfErrors;
                        numberOfErrors = result.validObject ? numberOfErrors : ++numberOfErrors ;
                        totalErrors = totalErrors + numberOfErrors;
                        const updatedObject = {
                            ...templateInformations[i].templates[j],
                            isWarning: result.duplicateName,
                            isCheck: result.validObject && !result.duplicateName,
                            isCross: !result.validObject
                        };
                        updatedTemplateInformation.push(updatedObject);
                    }else{
                        hasSystemError = true;
                        const updatedObject = {
                            ...templateInformations[i].templates[j],
                            isWarning: false,
                            isCheck: false,
                            isCross: false
                        };
                        updatedTemplateInformation.push(updatedObject);
                    }
                }
            }
            allValid = numberOfErrors === 0;
            validatedTemplatesCount = allValid ? ++validatedTemplatesCount : validatedTemplatesCount;
            const selected = allValid && !notSelected
            const disableSelection = notSelected || !allValid 
            updatedTemplatesInformations.push({ groupNumber : i, templates : updatedTemplateInformation  , allValid : allValid, numberOfErrors : `${numberOfErrors} ${this.label.VALIDATION_ERRORS}` , hasSystemError : hasSystemError, selected : selected  , disableSelection : disableSelection, displayValidationResult : !notSelected, mainTemplateName : updatedTemplateInformation[0].values.dataTemplate.templateName , mainTemplateInfo : `${updatedTemplateInformation[0].values.dataTemplate.templateName} - ${updatedTemplateInformation.length} ${this.label.TEMPLATE_CREATE}`});
        }
    
        this.templateInformations = updatedTemplatesInformations;
        this.allSelectedTemplatesValid =  selectedTemplatesCount === validatedTemplatesCount; 
        this.allInvalid = validatedTemplatesCount === 0;
    } 

    async _fetchFieldDetails(mainObject){
        const fieldsDetail = await fetchObjectFieldsDetail({ orgId : this.sourceOrg, mainObject : mainObject });
        return JSON.parse(fieldsDetail);
    }

    async _unzip_Decode(wholeObj) {
        var zip = await JSZip.loadAsync(wholeObj, { base64: true });
        return [zip, Object.keys(zip.files)];
    }

    _displayError(error){
        this.hasError = true;
        const errorMessage = reduceErrors(error);
        this._publishAlert(errorMessage, 'error', true);
    }

    _publishAlert(message, variant, dismiss){
        const alert = createAlert(message, variant, dismiss, this.communicationId);
        publish(this.messageContext, COPADO_ALERT_CHANNEL, alert);
    }

    _clearAlerts() {
        const alerts = this.template.querySelector('c-copado-alert-place-holder');
        if (alerts) {
            alerts.clear();
        }
    }
}