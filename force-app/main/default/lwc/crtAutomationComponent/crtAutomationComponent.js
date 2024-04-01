import { LightningElement, api } from "lwc";
import search from "@salesforce/apex/CustomLookupComponentHelper.search";
import { handleAsyncError } from "c/copadocoreUtils";

import ERROR_SEARCHING_RECORDS from "@salesforce/label/c.Error_Searching_Records";
import CRT_AUTOMATION from "@salesforce/label/c.CRT_AUTOMATION";
const SELECT_CRT_AUTOMATION = "Select " + CRT_AUTOMATION;

export default class CrtAutomationComponent extends LightningElement {
  @api previousValue = {};
  @api readOnlyData = false;

  selectedTest;
  initialSelection = [];

  label = {
    CRT_AUTOMATION,
    SELECT_CRT_AUTOMATION,
  };

  connectedCallback() {
    if (this.previousValue.hasOwnProperty("testId")) {
      this.selectedTest = this.previousValue;
      this.initialSelection = [
        {
          id: this.selectedTest.testId,
          sObjectType: "Test",
          icon: "standard:default",
          title: this.selectedTest.testName,
          subtitle: "Record Name is " + this.selectedTest.testName,
        },
      ];
    }
  }

  async handleLookupSearch(event) {
    const lookupElement = event.target;

    const safeSearch = handleAsyncError(this._search, {
      title: ERROR_SEARCHING_RECORDS,
    });

    const queryConfig = {
      searchField: "Name",
      objectName: "Test__c",
      searchKey: event.detail.searchTerm,
      extraFilterType: 'CrtTest',
      filterFormattingParameters: undefined,
    };

    this._lastResults = await safeSearch(this, {
      queryConfig,
      objectLabel: "Test",
    });
    if (this._lastResults) {
      lookupElement.setSearchResults(this._lastResults);
    }
  }

  getSelectedId(lookupData) {
    if (lookupData.detail.length) {
      this.selectedTest = {
        testId: lookupData.detail[0],
        testName: this._lastResults.find((re) => re.id === lookupData.detail[0])
          .title,
      };
    } else {
      this.selectedTest = undefined;
    }

    this.dispatchSelectedTest();
  }

  dispatchSelectedTest() {
    const recordEvent = new CustomEvent("selectedtestrecord", {
      detail: this.selectedTest,
      bubbles: true,
      composed: true,
    });
    this.dispatchEvent(recordEvent);
  }

  /**
   * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
   */
  _search(self, queryConfig) {
    return search(queryConfig);
  }
}