import { LightningElement } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class ToBeDeleted extends LightningElement {

    _subscription = {};
    _channelName = '/event/copado__MC_Result__e';

    connectedCallback() {
        try {
            this._handleSubscribe();
            this._registerErrorListener();
        } catch (err) {
            console.log(err);
        }
    }

    _handleSubscribe() {
        const callback = this._handlePlatformEvent.bind(this);

        subscribe(this._channelName, -1, callback).then((response) => {
            this._subscription = response;
            console.log(response);
        });
    }

    _handlePlatformEvent = (response) => {
        const event = response.data.payload;

        console.log(response);
        console.log(event);
    };
    _handleUnsubscribe() {
        unsubscribe(this._subscription, () => {});
    }

    _registerErrorListener() {
        onError((error) => {
            console.log(error)
        });
    }
}