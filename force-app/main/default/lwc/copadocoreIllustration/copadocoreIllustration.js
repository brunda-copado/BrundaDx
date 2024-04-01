import { LightningElement, api } from 'lwc';

export default class CopadocoreIllustration extends LightningElement {
    /**
     * The identifier for the image to show, in the format
     * `[category]:[description]`. See
     * https://www.lightningdesignsystem.com/components/illustration/ for what
     * each option renders.
     *
     */
    @api name;
    @api size;
    @api message;

    get imageClasses() {
        return `slds-size_${this.size}`;
    }

}