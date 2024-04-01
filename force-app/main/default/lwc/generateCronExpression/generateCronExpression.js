import { LightningElement } from 'lwc';
import { label, timeFrameOptions, daysOptions, HOURS_VALUE, DAYS_VALUE, WEEKS_VALUE } from './constants';

export default class GenerateCronExpression extends LightningElement {
    label = label;

    repeatEveryOptions = this._createOptions(32).slice(1);
    timeFrameOptions = timeFrameOptions;
    daysOptions = daysOptions;
    hoursOptions = this._createOptions(24, true);
    minutesOptions = this._createOptions(60, true);

    repeatEvery;
    timeFrame;
    days;
    hours;
    minutes;

    get weeksSelected() {
        return this.timeFrame === WEEKS_VALUE;
    }

    handleChangeRepeatEvery(event) {
        this.repeatEvery = event.detail.value;
    }

    handleChangeTimeFrame(event) {
        this.timeFrame = event.detail.value;
        switch (this.timeFrame) {
            case HOURS_VALUE:
                this.repeatEveryOptions = this._createOptions(24).slice(1);
                break;
            case DAYS_VALUE:
                this.repeatEveryOptions = this._createOptions(32).slice(1);
                break;
            case WEEKS_VALUE:
                this.repeatEveryOptions = this._createOptions(2).slice(1);
                break;
            default:
                break;
        }
        this.days = [];
        this.repeatEvery = '1';
    }

    handleChangeDays(event) {
        this.days = event.detail.value;
    }

    handleChangeHours(event) {
        this.hours = event.detail.value;
    }

    handleChangeMinutes(event) {
        this.minutes = event.detail.value;
    }

    openModal() {
        this._resetDefaults();
        this.template.querySelector('c-copadocore-modal').show();
    }

    handleCancelModal() {
        this._closeModal();
    }

    handleSaveModal() {
        const checkboxGroup = this.template.querySelector('lightning-checkbox-group');
        if (checkboxGroup) {
            const valid = checkboxGroup.checkValidity();
            if (!valid) {
                checkboxGroup.reportValidity();
                return;
            }
        }
        this._closeModal();
        this.dispatchEvent(new CustomEvent('generate', { detail: this._generateCronExpresion() }));
    }

    _closeModal() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    _generateCronExpresion() {
        const template = '{1} {2} {3} {4} {5} {6}';
        return template
            .replace('{1}', '0')
            .replace('{2}', this.minutes)
            .replace('{3}', this.timeFrame === HOURS_VALUE ? this.hours + '/' + this.repeatEvery : this.hours)
            .replace(
                '{4}',
                this.timeFrame === DAYS_VALUE && this.repeatEvery !== '1' ? '*/' + this.repeatEvery : this.timeFrame === DAYS_VALUE ? '*' : '?'
            )
            .replace('{5}', '*')
            .replace('{6}', this.timeFrame === WEEKS_VALUE ? this.days.join(',') : this.timeFrame === HOURS_VALUE ? '*' : '?');
    }

    _resetDefaults() {
        this.repeatEvery = this.repeatEveryOptions[0].value;
        this.timeFrame = this.timeFrameOptions[1].value;
        this.days = [];
        this.hours = this.hoursOptions[0].value;
        this.minutes = this.minutesOptions[0].value;
    }

    _createOptions(limit, timeFormat) {
        return [...Array(limit).keys()].map(number => {
            return {
                label: timeFormat ? ('0' + number.toString()).slice(-2) : number.toString(),
                value: number.toString()
            };
        });
    }
}