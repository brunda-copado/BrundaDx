import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { label, staticStrings } from './constants';
import getAvailableTemplateProviders from '@salesforce/apex/DataTemplateImportCtrl.getAvailableTemplateProviders';

export default class DataTemplateImportOptions extends NavigationMixin(LightningElement) {
    
    label = label;
    staticStrings = staticStrings;

    isLoading = false;
    selectedOption = '';
    selectedExtension = '';
    displayOption = true;
    displayExtensions = false;
    dataTemplateHomeUrl = '';
    extensions = [{ label: '-None-', value: '' }];
    get options() {
        return [
            { label: this.label.UPLOAD_FROM_FILE, value: this.staticStrings.file },
            { label: this.label.IMPORT_FROM_EXTENSION, value: this.staticStrings.extension }
        ];
    }

    get disableContinue(){
        return this.displayOption ? this.selectedOption ? false : true : this.selectedExtension ? false : true; 
    }

    async connectedCallback() {
        try{
            this.isLoading = true;
            const result = await getAvailableTemplateProviders();
            for(let key of Object.keys(result)){
                this.extensions.push({label : key, value : result[key]});
            }
        }catch(error){
            console.error(error);
        }
        this.isLoading = false;
    }

    handleOptionChange(event){
        this.selectedOption = event.detail.value;
    }

    handleExtensionChange(event){
        this.selectedExtension = event.detail.value;
    }
    
    handleContinue(event){
        this.displayOption =false;
        this.displayExtensions = this.selectedOption === this.staticStrings.extension;
        if(this.selectedOption == this.staticStrings.file){
            this._dispatchImportOptionEvent(this.selectedOption, '');
        }else if(this.selectedOption === this.staticStrings.extension && this.selectedExtension){
            this._dispatchImportOptionEvent(this.selectedOption, this.selectedExtension);
        }
    }

    handleCancel(event){
        window.history.back();
    }

    _dispatchImportOptionEvent(option, extension){
        this.dispatchEvent(
            new CustomEvent('selectimportoption', {
                detail: { option, extension}
            })
        );
    }
}