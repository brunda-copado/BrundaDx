import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { showToastError } from 'c/copadocoreToastNotification';
import { reduceErrors } from 'c/copadocoreUtils';
import getSnapshotToSprintMapping from '@salesforce/apex/SprintWallChartController.getMappingConfig';
import getChartConfig from '@salesforce/apex/SprintWallChartController.getChartData';
import saveChartData from '@salesforce/apex/SprintWallChartController.saveChartData';
import { customLabels, schema } from './constants';

export default class SprintMetricsBurnDown extends LightningElement {
    @api recordId;
    @api actualVelocityField;
    @api plannedVelocityField;
    @api legendPosition = 'top';
    @api objectName;
    @api title;

    isChartReady = false;
    burnDownChartConfiguration;
    chartConfig;
    mappingConfig = {};

    chartDates = [];
    burnDownData = { lineChartPlannedPoints: [], lineChartIdealPoints: [], lineChartActualPoints: [] };

    _sprintLength = 10;
    customLabels = customLabels;
    fields = [schema.START_DATE_FIELD, schema.END_DATE_FIELD];

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredSprint({ error, data }) {
        if (error) {
            const message = reduceErrors(error);
            showToastError(this, { message });
        } else if (data) {
            this._prepareChartData();
        }
    }

    connectedCallback() {
        this.chartFileName = this.title + ' SprintBurnDown.json';
        this._getMappingConfiguration()
            .then(() => {})
            .catch((errorGetChart) => {
                showToastError(this, { message: reduceErrors(errorGetChart) });
            });
    }

    @api
    async freeze() {
        const saveParameters = {
            sprintId: this.recordId,
            chartFileName: this.chartFileName,
            chartData: this.chartConfig.chartDataJson
        };

        try {
            await saveChartData(saveParameters);
            this.dispatchEvent(new CustomEvent('complete'));
        } catch (error) {
            const message = reduceErrors(error);
            showToastError(this, { message });
        }
    }

    _prepareChartData() {
        this._getChartConfiguration()
            .then(() => {})
            .catch((errorGetChart) => {
                showToastError(this, { message: reduceErrors(errorGetChart) });
            });
    }

    async _getMappingConfiguration() {
        try {
            const parameters = {
                plannedVelocityField: this.plannedVelocityField,
                actualVelocityField: this.actualVelocityField
            };
            this.mappingConfig = await getSnapshotToSprintMapping(parameters);
            if (Object.keys(this.mappingConfig).length > 0) {
                this.fields.push(this.objectName + '.' + this.mappingConfig.sprintActualVelocity);
                this.fields.push(this.objectName + '.' + this.mappingConfig.sprintPlannedVelocity);

                if (this.mappingConfig.sprintActualVelocity && this.mappingConfig.sprintPlannedVelocity) {
                    this._prepareChartData();
                }
            } else {
                const message = customLabels.SPRINT_SNAPSHOT_MAPPING_MISSING;
                showToastError(this, { message });
            }
        } catch (error) {
            console.error('errorGetMappingConfiguration', JSON.parse(JSON.stringify(error)));
            const message = reduceErrors(error);
            showToastError(this, { message });
        }
    }

    async _getChartConfiguration() {
        if (Object.keys(this.mappingConfig).length > 0) {
            try {
                const request = JSON.stringify({
                    objectId: this.recordId,
                    type: 'Line Burndown',
                    plannedVelocityField: this.plannedVelocityField,
                    actualVelocityField: this.actualVelocityField,
                    sprintActualVelocityField: this.mappingConfig.sprintActualVelocity,
                    sprintPlannedVelocityField: this.mappingConfig.sprintPlannedVelocity,
                    chartFileName: this.chartFileName
                });
                this.chartConfig = await getChartConfig({ request });
                this._prepareChartDates();
                this._prepareBurnDownChartData();
                this._getUsLineChartConfig();
            } catch (error) {
                console.error('errorGetChartConfigurationBurnDown', JSON.parse(JSON.stringify(error)));
                const message = reduceErrors(error);
                showToastError(this, { message });
            }
        }
    }

    _getUsLineChartConfig() {
        if (this.isChartReady) {
            const updatedData = [this.burnDownData.lineChartIdealPoints, this.burnDownData.lineChartActualPoints];
            const labels = this.chartDates;
            this.template.querySelector('c-chart-js-canvas').update(updatedData, labels);
            return;
        }

        this.burnDownChartConfiguration = {
            type: 'line',
            data: {
                datasets: [
                    {
                        fill: false,
                        label: customLabels.IDEAL_POINTS,
                        borderColor: ['#00C3EF'],
                        pointBackgroundColor: '#00C3EF',
                        pointBorderColor: '#00C3EF',
                        data: this.burnDownData.lineChartIdealPoints
                    },
                    {
                        fill: false,
                        label: customLabels.PENDING_POINTS,
                        borderColor: ['#192150'],
                        pointBackgroundColor: '#192150',
                        pointBorderColor: '#192150',
                        data: this.burnDownData.lineChartActualPoints
                    }
                ],
                labels: this.chartDates
            },
            options: {
                responsive: true,
                title: {
                    display: true,
                    text: customLabels.SPRINT_BURN_DOWN_CHART
                },
                legend: {
                    position: this.legendPosition,
                    labels: {
                        usePointStyle: true,
                        pointStyle: 'line'
                    }
                }
            }
        };
        this.isChartReady = true;
    }

    _prepareChartDates() {
        this.chartDates = [''];
        for (let i = 0; i < this.chartConfig.xAxisValues.length; i++) {
            this.chartDates.push('' + this.chartConfig.xAxisValues[i]);
        }
    }

    _prepareBurnDownChartData() {
        const parseChartDataJSON = JSON.parse(this.chartConfig.chartDataJson);
        this.burnDownData.lineChartIdealPoints = parseChartDataJSON[1];
        this.burnDownData.lineChartActualPoints = parseChartDataJSON[0];
    }
}