import { LightningElement, api, track } from 'lwc';

import getComplianceFileFromBackend from '@salesforce/apex/ComplianceRuleManagerCtrl.getComplianceFileFromBackend';
import validateCriterias from '@salesforce/apex/ComplianceRuleManagerCtrl.validateCriterias';
import saveCriterias from '@salesforce/apex/ComplianceRuleManagerCtrl.saveCriterias';
import deleteCriterias from '@salesforce/apex/ComplianceRuleManagerCtrl.deleteCriterias';
import criteriasOfRule from '@salesforce/apex/ComplianceRuleManagerCtrl.criteriasOfRule';
import validatePermissions from '@salesforce/apex/ComplianceRuleManagerCtrl.validatePermissions';

import { showToastWarning, showToastError } from 'c/copadocoreToastNotification';
import { flushPromises } from 'c/copadocoreUtils';

import Graph from './metadataGraph/baseGraph';
import ComplianceGraph from './metadataGraph/complianceGraph';
import { getOperatorListByType, getValueBoxType, setValueBoxForm, filterNodeListByNode, criteriaListToSObjectList } from './utils';
import { label, schema, emptyCriteria, lightningBoxTypes } from './constants';

import readModeTemplate from './complianceCriteriaManager.html';
import editModeTemplate from './complianceCriteriaManagerEditMode.html';

export default class ComplianceCriteriaManager extends LightningElement {
    @api recordId;

    @track metadataTypes = [];
    @track nodeList = [];
    @track criterias = [];

    label = label;
    switchIconName = 'utility:chevrondown';
    metadataTypeSelected = '';
    isLoading = false;
    criteriaLogic = '';
    saveError = {
        isError: false,
        message: ''
    };
    hasPermissions = true;
    editMode = false;

    _metadataGraph;
    _legacyCriterias = [];
    _criteriasToDeleteSObjectList = [];

    constructor() {
        super();
        this.criterias = [JSON.parse(JSON.stringify(emptyCriteria))];
    }

    render() {
        return this.editMode ? editModeTemplate : readModeTemplate;
    }

    async connectedCallback() {
        this.isLoading = true;

        this.hasPermissions = await this._handleError(this._validatePermissions);
        if (this.hasPermissions) {
            await this._handleError(this._loadMetadataGraph);
            await this._handleError(this._loadLegacyCriterias);
        }

        this.isLoading = false;
    }

    // PUBLIC

    get isMetadataSelected() {
        return this.metadataTypeSelected !== '';
    }

    get canDeleteRows() {
        return this.criterias.length > 1;
    }

    toEditMode() {
        this.editMode = true;
    }

    async toReadMode() {
        this.isLoading = true;

        this.editMode = false;
        this._criteriasToDeleteSObjectList = [];
        await this._loadLegacyCriterias();
        this.saveError = {
            isError: false,
            message: ''
        };

        this.isLoading = false;
    }

    preventClick(evt) {
        if (!this.editMode) {
            evt.preventDefault();
        }
    }

    handleMetadataTypeChange(event) {
        if (this.metadataTypes.length > 0) {
            this.metadataTypeSelected = event.detail.value;
            this.nodeList = this._metadataGraph.getNodeList(this.metadataTypeSelected);
        }
    }

    handleNodeChange(event) {
        if (this.nodeList) {
            const selectedNode = event.detail.value;
            this.nodeList = filterNodeListByNode(this.nodeList, selectedNode);

            const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);
            criteria.node = selectedNode;
            criteria.fieldList = this._metadataGraph.getFieldList(selectedNode);
        }
    }

    handleFieldChange(event) {
        const selectedField = event.detail.value;
        const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);

        criteria.field = selectedField;
        criteria.fieldType = this._metadataGraph.getValueType(criteria.node, selectedField);
        criteria.operatorList = getOperatorListByType(criteria.fieldType);

        setValueBoxForm(criteria);
    }

    handleOperatorChange(event) {
        const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);
        criteria.operator = event.detail.value;

        setValueBoxForm(criteria);
    }

    handleValueChange(event) {
        const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);
        let value;
        if (criteria.valueBoxType === lightningBoxTypes.CHECKBOX) {
            value = `${event.detail.checked}`;
            criteria.valueCheckboxValue = event.detail.checked;
        } else {
            value = event.detail.value;
        }

        criteria.value = value;
    }

    handleCriteriaLogicChange(event) {
        this.criteriaLogic = event.target.value;
    }

    changeExpandableSection() {
        this.template.querySelector('div[data-id="CriteriaManagerAccordion"]').classList.toggle('slds-is-open');
        this.switchIconName = this.switchIconName === 'utility:chevronright' ? 'utility:chevrondown' : 'utility:chevronright';
    }

    addEmptyCriteria() {
        const criteria = JSON.parse(JSON.stringify(emptyCriteria));
        criteria.Id = this.criterias.length + 1;
        this.criterias.push(criteria);
    }

    removeCriteria(event) {
        const selectedCriteriaId = +event.target.dataset.criteriaId;
        const selectedCriteria = this.criterias.find((criteriaItem) => criteriaItem.Id === selectedCriteriaId);

        if (selectedCriteria.sfId) {
            this._criteriasToDeleteSObjectList.push({
                sObjectType: schema.COMPLIANCE_RULE_CRITERIA.objectApiName,
                Id: selectedCriteria.sfId
            });
        }

        this._legacyCriterias = this._legacyCriterias.filter((criteria) => criteria.Id !== selectedCriteria.sfId);

        if (this.criterias.length === 1) {
            this.nodeList = this._metadataGraph.getNodeList(this.metadataTypeSelected);
            this.criterias = [JSON.parse(JSON.stringify(emptyCriteria))];
        } else if (this.criterias.length > 1) {
            this.criterias = this.criterias.filter((criteria) => criteria.Id !== selectedCriteriaId);
            this.criterias = this.criterias.map((criteria, index) => {
                criteria.Id = index + 1;
                return criteria;
            });
        }
    }

    async save() {
        this.isLoading = true;

        this.criteriaLogic = this._getUpdatedLogic(this.criteriaLogic, this.criterias);

        const criteriaSObjectList = criteriaListToSObjectList(this.criterias, this.recordId);
        try {
            await validateCriterias({
                criterias: criteriaSObjectList,
                criteriaLogic: this.criteriaLogic
            });

            if (this._criteriasToDeleteSObjectList.length > 0) {
                await deleteCriterias({
                    criterias: this._criteriasToDeleteSObjectList
                });
                this._criteriasToDeleteSObjectList = [];
            }

            await saveCriterias({
                criteria: criteriaSObjectList,
                criteriaLogic: this.criteriaLogic,
                metadataType: this.metadataTypeSelected
            });

            await this._loadLegacyCriterias();

            this.saveError = {
                isError: false,
                message: ''
            };
        } catch (e) {
            this.saveError = {
                isError: true,
                message: e.body.message
            };
            await flushPromises();
            this.template.querySelector('c-copadocore-error-popover')?.openPopOver();
        }

        this.isLoading = false;

        if (this.saveError && !this.saveError.isError) {
            this.toReadMode();
        }
    }

    resetData() {
        this.metadataTypeSelected = '';
        this.nodeList = this._metadataGraph.getNodeList(this.metadataTypeSelected);
        this.criterias = [JSON.parse(JSON.stringify(emptyCriteria))];
        this._legacyCriterias.forEach((criteria) => {
            if (!this._criteriasToDeleteSObjectList.find((criteriaToDelete) => criteriaToDelete.Id === criteria.Id)) {
                this._criteriasToDeleteSObjectList.push({
                    sObjectType: schema.COMPLIANCE_RULE_CRITERIA.objectApiName,
                    Id: criteria.Id
                });
            }
        });
    }

    // PRIVATE

    async _validatePermissions() {
        const error = (await validatePermissions()) || '';
        if (error) {
            const toastOptions = { mode: 'sticky', message: error };
            if (error === label.CCH_MISSING_API_KEY) {
                showToastError(this, toastOptions);
            } else {
                showToastWarning(this, toastOptions);
            }
        }

        return error === '';
    }

    async _getMetadataGraph() {
        const complianceFileAsString = await getComplianceFileFromBackend();
        const complianceJSON = JSON.parse(complianceFileAsString);

        const baseGraph = new Graph();
        baseGraph.importJson(complianceJSON);

        return new ComplianceGraph(baseGraph);
    }

    async _loadMetadataGraph() {
        this._metadataGraph = await this._getMetadataGraph();
        this.metadataTypes = this._metadataGraph.getMetadataTypeOptions();
    }

    async _loadLegacyCriterias() {
        const existingCriteria = [];

        this._legacyCriterias = await criteriasOfRule({
            ruleId: this.recordId
        });

        if (this._legacyCriterias.length > 0 && this._metadataGraph) {
            this.metadataTypeSelected = this._legacyCriterias[0][schema.COMPLIANCE_RULE.objectApiName.replace('__c', '__r')][
                schema.COMPLIANCE_RULE_METADATA_TYPE.fieldApiName
            ];

            this.criteriaLogic = this._legacyCriterias[0][schema.COMPLIANCE_RULE.objectApiName.replace('__c', '__r')][
                schema.COMPLIANCE_RULE_CRITERIA_LOGIC.fieldApiName
            ];

            this._legacyCriterias.forEach((criteria) => {
                this.criteriaLogic = this.criteriaLogic.replace(
                    criteria[schema.COMPLIANCE_CRITERIA_NAME.fieldApiName],
                    criteria[schema.COMPLIANCE_CRITERIA_ORDER.fieldApiName]
                );
            });

            this.nodeList = this._metadataGraph.getNodeList(this.metadataTypeSelected);

            this._legacyCriterias.forEach((legacyCriteria, index) => {
                const node = legacyCriteria[schema.COMPLIANCE_CRITERIA_NODE.fieldApiName];
                const field = legacyCriteria[schema.COMPLIANCE_CRITERIA_FIELD.fieldApiName];
                const operator = legacyCriteria[schema.COMPLIANCE_CRITERIA_OPERATOR.fieldApiName].toLowerCase();
                const value = legacyCriteria[schema.COMPLIANCE_CRITERIA_VALUE.fieldApiName];
                const fieldType = legacyCriteria[schema.COMPLIANCE_CRITERIA_FIELD_TYPE.fieldApiName];

                this.nodeList = filterNodeListByNode(this.nodeList, node);
                const fieldList = this._metadataGraph.getFieldList(node);
                const operatorList = getOperatorListByType(fieldType);
                const valueBoxType = getValueBoxType(fieldType, operator);

                existingCriteria.push({
                    Id: index + 1,
                    node,
                    field,
                    operator,
                    value,
                    fieldList,
                    operatorList,
                    fieldType,
                    valueBoxType,
                    valueCheckboxValue: valueBoxType === lightningBoxTypes.CHECKBOX ? value === 'true' : false,
                    isBoolean: valueBoxType === lightningBoxTypes.CHECKBOX,
                    sfId: legacyCriteria.Id
                });
            });

            this.criterias = JSON.parse(JSON.stringify(existingCriteria));
        } else {
            this.criterias = [JSON.parse(JSON.stringify(emptyCriteria))];
        }
    }

    _getUpdatedLogic(logic, criterias) {
        criterias.forEach((criteria, index) => {
            const row = (index + 1).toString();

            if (
                !criteria.sfId &&
                !logic
                    .replace(/\(|\)/g, '')
                    .replace(/AND|OR/g, '')
                    .split(' ')
                    .includes(row)
            ) {
                if (index === 0) {
                    logic += row;
                } else {
                    logic += ' AND ' + row;
                }
            }
        });

        return logic;
    }

    async _handleError(fn, ...params) {
        let result;

        try {
            result = await fn.call(this, ...params);
        } catch (err) {
            showToastError(this, { message: err.message || err.body.message });
        }

        return result;
    }
}