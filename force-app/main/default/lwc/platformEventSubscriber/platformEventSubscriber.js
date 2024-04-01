import { LightningElement, api } from 'lwc';
import { subscribe, onError, unsubscribe } from 'lightning/empApi';
import { reduceErrors } from 'c/copadocoreUtils';

import InvalidChannel from '@salesforce/label/c.InvalidChannel';

export default class PlatformEventSubscriber extends LightningElement {
    @api channel;
    @api subscribeOnLoad = false;

    _subscription;


    @api
    async subscribe(channel) {
        this.channel = channel || this.channel;

        if (!this.channel) {
            this.fireErrorEvent(InvalidChannel);
            return;
        }

        try {
            this._subscription = await subscribe(this.channel, -1, (response) => {
                const detail = { response }
                this.dispatchEvent(new CustomEvent('message', { detail }));
            });
        } catch (error) {
            this.fireErrorEvent(error);
        }
    }


    @api
    unsubscribe() {
        if (this._subscription) {
            unsubscribe(this._subscription, console.info);
        }
    }


    connectedCallback() {
        onError((error) => {
            this.fireErrorEvent(error);
        });

        window.addEventListener('beforeunload', () => {
            this.unsubscribe();
        });

        if (this.subscribeOnLoad) {
            this.subscribe();
        }
    }


    fireErrorEvent(error) {
        const errorMessage = reduceErrors(error);
        const detail = { errorMessage };

        console.error(error);
        this.dispatchEvent(new CustomEvent('error', { detail }));
    }


    disconnectedCallback() {
        this.unsubscribe();
    }
}