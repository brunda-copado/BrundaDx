import { LightningElement, api } from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class ChartJsCanvas extends LightningElement {
    @api chartConfig;

    myChartConfig;
 
    isChartJsInitialized;
    renderedCallback() {
        if (this.isChartJsInitialized) {
            return;
        }

        this.myChartConfig = JSON.parse(JSON.stringify(this.chartConfig));

        this._loadResources(this);
    }

    _loadResources(component) {
        // load chartjs from the static resource
        Promise.all([loadScript(component, chartjs + '/chartJs/chart.js')])
        .then(() => {
            // disable CSS injection
            window.Chart.platform.disableCSSInjection = true;
            this.isChartJsInitialized = true;
            //console.log('this.chartConfig###' + JSON.stringify(this.chartConfig));
            const ctx = this.template.querySelector('canvas.charts').getContext('2d');
            this.chart = new window.Chart(ctx, this.myChartConfig);
        })
        .catch(error => {
            console.error('loadResourcesChartJS' + error.message);
        });
    }

    @api update(updatedData,labels){

        for(var i = 0; i < updatedData.length; i++){
            this.chart.data.datasets[i].data = updatedData[i];
        }
        if(labels){
            this.chart.data.labels = labels;
        }
        this.chart.update();
    }
}