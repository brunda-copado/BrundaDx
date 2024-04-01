import { LightningElement, api } from 'lwc';
import { default as images, empty } from './images/index';

export { images };

export default class IllustrationImage extends LightningElement {
    @api imageName;

    render() {
        const { imageName } = this;

        if (images[imageName]) {
            return images[imageName];
        }
        return empty;
    }
}