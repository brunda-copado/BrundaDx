import { api, wire, LightningElement } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { handleAsyncError, reduceErrors } from 'c/copadocoreUtils';

import search from '@salesforce/apex/CustomLookupComponentHelper.search';

import { labels, schema } from './constants';

export default class SetReleaseVersion extends LightningElement {
  @api recordId;

  labels = labels;
  schema = schema;

  releaseId;
  prevReleaseRecord;
  prevReleaseVersion=labels.RELEASE_NOT_FOUND;
  error;
  versionType = '';
  newVersion;
  isDisabled = true;

  @wire(getRecord, { recordId: '$recordId', fields: [schema.VERSION, schema.PROJECT] })
  releaseRecord;

  @wire(getRecord, { recordId: '$releaseId', fields: [schema.VERSION, schema.STATUS, schema.PROJECT_NAME] })
  wiredFunction({ data, error }) {
    if (data) {
      this.prevReleaseVersion = getFieldValue(data, schema.VERSION);
      this.status = getFieldValue(data, schema.STATUS);
      this.projectName = getFieldValue(data, schema.PROJECT_NAME);
    } else if (error) {
      this.error = {
        title: labels.Error,
        message: reduceErrors(error)
      };
    }
  }

  // eslint-disable-next-line no-dupe-class-members
  get options() {
    return [
      { label: labels.Version_Type_Major, value: 'Major' },
      { label: labels.Version_Type_Minor, value: 'Minor' },
      { label: labels.Version_Type_Patch, value: 'Patch' }
    ];
  }

  async handleLookupSearch(event) {
    const lookupElement = event.target;
    const projectId = getFieldValue(this.releaseRecord?.data, schema.PROJECT);

    const safeSearch = handleAsyncError(this._search, {
      title: labels.Error_Searching_Records
    });

    if (projectId) {
      const queryConfig = {
        searchField: 'Name',
        objectName: schema.RELEASE_OBJECT.objectApiName,
        searchKey: event.detail.searchTerm,
        extraFilterType: 'PreviousReleaseFilter',
        filterFormattingParameters: [projectId, this.recordId],
        additionalFields: [schema.STATUS.fieldApiName, schema.PROJECT_NAME.fieldApiName, schema.VERSION.fieldApiName]
      };

      this._lastResults = await safeSearch(this, { queryConfig, objectLabel: 'Release', iconName: 'custom:custom13', subtitleField: schema.VERSION.fieldApiName });
    }
    
    if (this._lastResults) {
      lookupElement.setSearchResults(this._lastResults);
    } else {
      lookupElement.setSearchResults(labels.No_results);
    }
  }

  addToSelectedRecord(lookupData) {
    if (lookupData.detail.length) {
      this.releaseId = lookupData.detail[0];
    } else {
      this.releaseId='';
      this.prevReleaseVersion=labels.RELEASE_NOT_FOUND;
    }
  }

  handleInputChange(event) {
    this.newVersion = event.target.value;
  }
  
  handleChange(event) {
    this.versionType = event.detail.value;
    this.isDisabled = false;

    this.newVersion = this.prevReleaseVersion !== labels.RELEASE_NOT_FOUND ? this.getLatestVersion() : '';
  }

  handleSave() {
    if (this.isInputValid()) {
      this.updateRelease();
    }
  }

  updateRelease() {
    const fields = {};
      fields[schema.RELEASE_ID.fieldApiName] = this.recordId;
      fields[schema.VERSIONTYPE.fieldApiName] = this.versionType
      fields[schema.VERSION.fieldApiName] = this.newVersion;

      const recordInput = { fields };
        updateRecord(recordInput)
          .then(() => {
            this.dispatchEvent(new ShowToastEvent({
              title: labels.SUCCESS,
              message: labels.Set_Release_Success,
              variant: 'success'
            }));
      
            this.handleCancel();
          })
          .catch(error => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: labels.Update_Record_Error_Title,
                message: error.body.message,
                variant: 'error'
              }));
          });
  }

  getLatestVersion() {
    let versionArray = this.prevReleaseVersion?.split('.').map(Number);

    switch (this.versionType) {
      case 'Major': 
        versionArray[0] = versionArray[0] + 1;
        break;

      case 'Minor':
        if (versionArray.length === 1) {
        versionArray.push(1);
        } else {
          versionArray[1] = versionArray[1] + 1;
        }
        break;

      case 'Patch':
        if (versionArray.length === 1) {
          versionArray.push(0);
          versionArray.push(1);
        } else if (versionArray.length === 2) {
          versionArray.push(1);
        } else {
          versionArray[2] = versionArray[2] + 1;
        }
        break;

      default:  break;
    }

    return this.versionType === 'Major' ? versionArray[0].toString() : versionArray.join('.');
  }

  isInputValid() {
    const allValid = [...this.template.querySelectorAll('.validate')]
      .reduce((validSoFar, inputFields) => {
        inputFields.reportValidity();
        return validSoFar && inputFields.checkValidity();
      }, true);

    return allValid;
  }

  _search(self, queryConfig) {
    return search(queryConfig);
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}