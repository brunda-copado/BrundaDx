import { LightningElement ,api} from 'lwc';
import OPTIONS_SELECTED from '@salesforce/label/c.FilterOptionsSelected';
import { formatLabel } from 'c/copadocoreUtils';

export default class MultiSelectPicklist extends LightningElement {
    @api label;
    
    @api
    get disabled() {
        return this._disabled;
    }
    set disabled(value) {
        this._disabled = value;
        this._handleDisabled();
    }

    @api
    get valuesSelected() {
        return this._valuesSelected;
    }
    set valuesSelected(value) {
        this._valuesSelected = value;
    }

    @api options = [];

    inputValue;
    value = [];
    hasRendered = false;
    comboboxIsRendered = false;
    dropDownInFocus = false;

    _disabled = false;
    _valuesSelected = [];

    @api
    clear() {
        this._unselectAllOption();
    }

    connectedCallback() {
        this._initialSelections();

    }

    renderedCallback() {
        if (!this.hasRendered) {
            this._handleDisabled();
        }
        this.hasRendered = true;
    }

    handleClick() {
        const sldsCombobox = this.template.querySelector('.slds-combobox');
        if (sldsCombobox) {
            sldsCombobox.classList.toggle('slds-is-open');
            if (!this.comboboxIsRendered) {
                this.comboboxIsRendered = true;
            }
        }

    }

    handleSelection(event) {
        const value = event.currentTarget.dataset.value;
        if (value === '') {
            this.handleAllOption();
        } else {
            this.handleOption(event, value);
        }
        const input = this.template.querySelector('input');
        if (input) {
            input.focus();
        }
        this.sendValues();
    }

    sendValues() {
        const values = this.value.map((option) => option.value);
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: values
            })
        );
    }

    handleAllOption() {
        this.inputValue = this.options[0].label;
        this._selectAllOption();
        this._closeDropbox();
    }

    handleOption(event, value) {
        if (this._optionIsSelected(value)) {
            this._handleOptionSelection(false, value);
        } else {
            this._handleOptionSelection(true, value);
        }
        this._setInputValue();
    }

    handleBlur() {
        if (!this.dropDownInFocus) {
            this._closeDropbox();
        }
    }

    handleMouseLeave() {
        this.dropDownInFocus = false;
    }

    handleMouseEnter() {
        this.dropDownInFocus = true;
    }

    _handleDisabled() {
        const input = this.template.querySelector('input');
        if (input) {
            input.disabled = this.disabled;
        }
    }

    _closeDropbox() {
        const sldsCombobox = this.template.querySelector('.slds-combobox');
        if (sldsCombobox) {
            sldsCombobox.classList.remove('slds-is-open');
        }
    }

    _selectAllOption() {
        this._handleOptionsSelection(true);
        
    }

    _unselectAllOption() {
        this._handleOptionsSelection(false);
    }

    _optionIsSelected(value) {
        const option = this.options.find((each) => each.value === value);
        return option.isSelected;
    }

    _initialSelections(){
        const options = []; 
        this.options.forEach((each)=>{
            const option = Object.assign({}, each);
            if(this.valuesSelected.includes(option.value)){
                option.isSelected =true;
                const selectedOption = this.options.find((each) => each.value === option.value);
                this.value.push(selectedOption);
            } else{
                option.isSelected =false;
            }
            options.push(option);
          });
          this.options = [];
          this.options = options;
          this._setInputValue();
    }

    _handleOptionSelection(isSelected ,value) {
        const options = []; 
        this.options.forEach((option)=>{
            if(option.value === value ){
                option.isSelected = isSelected;
                if(isSelected) {
                    this.value.push(option);
                } else{
                    this.value = this.value.filter((each) => each.value !== value);
                }
                
            } 
            options.push(option);
          });
          this.options = options;

    }

    _handleOptionsSelection(isSelected) {
        const options = []; 
        this.value = [];
        this.options.forEach((option)=>{
                option.isSelected = isSelected;
                if(isSelected) {
                    this.value.push(option);
                }
                options.push(option);
          });
          this.options = options;
          this._setInputValue();  
    }

    _setInputValue() {
        this.inputValue =this.value && this.value.length 
        ? formatLabel(OPTIONS_SELECTED, [this.value.length])
        : formatLabel(OPTIONS_SELECTED, [0]);
    }
}