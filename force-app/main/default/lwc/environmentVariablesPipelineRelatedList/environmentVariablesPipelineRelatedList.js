import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import { handleAsyncError, reduceErrors, namespace } from "c/copadocoreUtils";

import { getColumnsConfig, getData } from "./utils";
import {
  showToastSuccess,
  showToastError
} from "c/copadocoreToastNotification";

import ENVIRONMENT_VARIABLE_OBJECT from "@salesforce/schema/Environmental_Variable__c";

import Fetch_Columns_Config_Error from "@salesforce/label/c.Fetch_Columns_Config_Error";
import Fetch_Data_Error from "@salesforce/label/c.Fetch_Data_Error";
import NEW from "@salesforce/label/c.NEW";
import Cancel from "@salesforce/label/c.Cancel";
import DELETE from "@salesforce/label/c.DELETE";
import EDIT from "@salesforce/label/c.EDIT";
import Delete_Confirmation from "@salesforce/label/c.Delete_Confirmation";
import Error_Deleting_Record from "@salesforce/label/c.Error_Deleting_Record";
import Record_Deleted_Successfully from "@salesforce/label/c.Record_Deleted_Successfully";
import onDelete from "@salesforce/apex/EnvironmentVarPipelineRelatedListCtrl.onDelete";

import { getUpgradedColumnConfiguration } from "c/datatableService";

const actions = [
  { label: EDIT, name: "edit" },
  { label: DELETE, name: "delete" }
];

export default class EnvironmentVariablesPipelineRelatedList extends LightningElement {
  @api recordId;
  @api objectApiName;

  label = {
    NEW,
    Cancel,
    DELETE,
    Delete_Confirmation,
    Error_Deleting_Record,
    Record_Deleted_Successfully
  };

  showSpinner;

  actions = actions;

  _fieldset = "RelatedList";

  columns;
  allRows;
  record;

  async connectedCallback() {
    this.showSpinner = true;
    await this._setTableInformation();
    this.showSpinner = false;
  }

  @wire(getObjectInfo, { objectApiName: ENVIRONMENT_VARIABLE_OBJECT })
  environmentVariableInfo;

  // TEMPLATE
  get body() {
    return `${this.label.Delete_Confirmation} ${
      this.environmentVariableInfo?.data?.label
        ? this.environmentVariableInfo.data.label.toLowerCase()
        : ""
    }?`;
  }

  get title() {
    return `${this.label.DELETE} ${this.environmentVariableInfo?.data?.label}`;
  }

  get labelPlural() {
    return `${this.environmentVariableInfo?.data?.labelPlural}`;
  }

  get isPipeline() {
    return (
      `${this.objectApiName}` ==
      (namespace ? namespace + "Deployment_Flow__c" : "Deployment_Flow__c")
    );
  }

  show() {
    this.template.querySelector("c-copadocore-modal").show();
  }

  hide() {
    this.template.querySelector("c-copadocore-modal").hide();
  }

  handleCancel() {
    this.hide();
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    switch (actionName) {
      case "edit":
        this._handleEditEnvironmentVariable(row);
        break;
      case "delete":
        this._handleDeleteRecord(row);
        break;
      default:
    }
  }

  handleNew() {
    this._handleEditEnvironmentVariable();
  }

  _handleEditEnvironmentVariable(row) {
    const manageEnvironmentVariablePopup = this.template.querySelector(
      "c-manage-environment-variable-popup"
    );
    manageEnvironmentVariablePopup.record = row ? row : "";
    manageEnvironmentVariablePopup.parentId = this.recordId;
    manageEnvironmentVariablePopup.sObjectName = this.objectApiName;
    manageEnvironmentVariablePopup.show();
    manageEnvironmentVariablePopup.setDataTable();
  }

  _handleDeleteRecord(row) {
    this.record = row;
    this.show();
  }

  async handleDelete() {
    this.hide();

    const result = await onDelete({
      environmentVariable: this.record,
      sObjectName: this.objectApiName
    });
    if (result !== undefined) {
      showToastSuccess(this, {
        title: `${this.environmentVariableInfo.data.label} ${this.label.Record_Deleted_Successfully}.`
      });
    }
    this.handleRefresh();
  }

  async handleRefresh() {
    this.showSpinner = true;
    await this._setTableInformation();
    this.showSpinner = false;
  }

  // PRIVATE

  async _setTableInformation() {
    const [columns, rows] = await Promise.all([
      this._getColumnsConfig(),
      this._getRowsData()
    ]);

    if (!(columns && rows)) {
      return;
    }
  }

  async _getColumnsConfig() {
    const safeFetchColumnsConfig = handleAsyncError(getColumnsConfig, {
      title: Fetch_Columns_Config_Error
    });

    const columnsConfiguration = {
      objectApiName: ENVIRONMENT_VARIABLE_OBJECT.objectApiName,
      fieldSetName: this._fieldset,
      editable: false,
      hideDefaultColumnsActions: true,
      searchable: false,
      sortable: false
    };

    const columns = await safeFetchColumnsConfig(this, {
      columnsConfiguration
    });
    if (columns && columns.length) {
      const formatCol = this.formatColumn(columns);
      const columnConfigs = getUpgradedColumnConfiguration(
        formatCol,
        actions,
        false
      );
      this.columns = columnConfigs;
    }

    return columns;
  }

  async _getRowsData() {
    try {
      const safeFetchData = handleAsyncError(getData, {
        title: Fetch_Data_Error
      });
      const rows = await safeFetchData(this, {
        recordId: this.recordId,
        objectApiName: this.objectApiName
      });
      this.allRows = rows;
      return rows;
    } catch (error) {
      const errorMessage = reduceErrors(error);
      showToastError(this, { message: errorMessage });
    }
  }

  handleSave() {
    this.handleRefresh();
  }

  formatColumn(columns) {
    if (columns) {
      let result = JSON.parse(JSON.stringify(columns));
      result.forEach((col) => {
        if (col.fieldName === "LinkName") {
          col.fieldName = "Name";
          col.type = "text";
        }
      });
      return result;
    }
  }
}