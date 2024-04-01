import { LightningElement, api, track } from 'lwc';
import { getPathPrefix, getToken } from 'lightning/configProvider';
import dir from '@salesforce/i18n/dir';

export default class CopadocoreCustomIcon extends LightningElement {
    personalizedColor;
    state = {};
    @track privateColor;
    @api alternativeText;

    @api get color() {
        return this.privateColor;
    }
    set color(value) {
        this.privateColor = value;
    }

    @api get src() {
        return this.privateSrc;
    }
    set src(value) {
        this.privateSrc = value;
        if (!value) {
            this.state.iconName = this.iconName;
            this.classList.remove('slds-icon-standard-default');
        }
        if (value && isIE11()) {
            this.setDefault();
            return;
        }
        this.state.src = value;
    }
    @api get iconName() {
        return this.privateIconName;
    }
    set iconName(value) {
        this.privateIconName = value;

        if (this.src) {
            return;
        }
        if (isValidName(value)) {
            const isAction = getCategory(value) === 'action';

            if (value !== this.state.iconName) {
                classListMutation(this.classList, {
                    'slds-icon_container_circle': isAction,
                    [computeSldsClass(value)]: true,
                    [computeSldsClass(this.state.iconName)]: false
                });
            }
            this.state.iconName = value;
        } else {
            console.warn(`<c-icon> Invalid icon name ${value}`); // eslint-disable-line no-console
            classListMutation(this.classList, {
                'slds-icon_container_circle': false,
                [computeSldsClass(this.state.iconName)]: false
            });
            this.state.iconName = undefined;
        }
    }

    @api get size() {
        return normalizeString(this.state.size, {
            fallbackValue: 'medium',
            validValues: ['xx-small', 'x-small', 'small', 'medium', 'large']
        });
    }
    set size(value) {
        this.state.size = value;
    }

    @api get variant() {
        return normalizeVariant(this.state.variant, this.state.iconName);
    }
    set variant(value) {
        this.state.variant = value;
    }

    get href() {
        return this.src || getIconPath(this.iconName, dir);
    }

    get computedClass() {
        const { normalizedSize, normalizedVariant } = this;
        const classes = classSet(this.svgClass);

        if (this.privateColor) {
            this.personalizedColor = `fill:${this.privateColor};`;
        }
        if (normalizedVariant !== 'bare') {
            classes.add('slds-icon');
        }

        switch (normalizedVariant) {
            case 'error':
                classes.add('slds-icon-text-error');
                break;
            case 'warning':
                classes.add('slds-icon-text-warning');
                break;
            case 'success':
                classes.add('slds-icon-text-success');
                break;
            case 'inverse':
            case 'bare':
                break;
            default:
                if (!this.src) {
                    classes.add('slds-icon-text-default');
                }
        }

        if (normalizedSize !== 'medium') {
            classes.add(`slds-icon_${normalizedSize}`);
        }

        return classes.toString();
    }

    get name() {
        return getName(this.iconName);
    }

    get normalizedSize() {
        return normalizeString(this.size, {
            fallbackValue: 'medium',
            validValues: ['xx-small', 'x-small', 'small', 'medium', 'large']
        });
    }

    setDefault() {
        this.state.src = undefined;
        this.state.iconName = 'standard:default';
        this.classList.add('slds-icon-standard-default');
    }

    connectedCallback() {
        this.classList.add('slds-icon_container');
    }
}

const validNameRe = /^([a-zA-Z]+):([a-zA-Z]\w*)$/;

function getCategory(iconName) {
    return iconName.split(':')[0];
}

function getName(iconName) {
    return iconName.split(':')[1];
}

function normalizeVariant(variant, iconName) {
    if (variant === 'bare') {
        variant = 'inverse';
    }

    if (getCategory(iconName) === 'utility') {
        return normalizeString(variant, {
            fallbackValue: '',
            validValues: ['error', 'inverse', 'warning', 'success']
        });
    }
    return 'inverse';
}

function normalizeString(value, config = {}) {
    const { fallbackValue = '', validValues, toLowerCase = true } = config;
    let normalized = (typeof value === 'string' && value.trim()) || '';
    normalized = toLowerCase ? normalized.toLowerCase() : normalized;
    if (validValues && validValues.indexOf(normalized) === -1) {
        normalized = fallbackValue;
    }
    return normalized;
}

function isValidName(iconName) {
    return validNameRe.test(iconName);
}

function classListMutation(classList, config) {
    Object.keys(config).forEach((key) => {
        if (typeof key === 'string' && key.length) {
            if (config[key]) {
                classList.add(key);
            } else {
                classList.remove(key);
            }
        }
    });
}

function computeSldsClass(iconName) {
    if (isValidName(iconName)) {
        const category = getCategory(iconName);
        const name = getName(iconName).replace(/_/g, '-');
        return `slds-icon-${category}-${name}`;
    }
    return '';
}

function isIE11() {
    return /Trident.*rv[ :]*11\./.test(navigator.userAgent);
}

function getIconPath(iconName, direction = 'ltr') {
    let pathPrefix;
    pathPrefix = pathPrefix !== undefined ? pathPrefix : getPathPrefix();

    if (isValidName(iconName)) {
        const baseIconPath = getBaseIconPath(getCategory(iconName), direction);
        if (baseIconPath) {
            if (isIframeInEdge()) {
                const origin = `${window.location.protocol}//${window.location.host}`;
                return `${origin}${pathPrefix}${baseIconPath}#${getName(iconName)}`;
            }
            return `${pathPrefix}${baseIconPath}#${getName(iconName)}`;
        }
    }
    return '';
}

const tokenNameMap = Object.assign(Object.create(null), {
    action: 'lightning.actionSprite',
    custom: 'lightning.customSprite',
    doctype: 'lightning.doctypeSprite',
    standard: 'lightning.standardSprite',
    utility: 'lightning.utilitySprite'
});

const tokenNameMapRtl = Object.assign(Object.create(null), {
    action: 'lightning.actionSpriteRtl',
    custom: 'lightning.customSpriteRtl',
    doctype: 'lightning.doctypeSpriteRtl',
    standard: 'lightning.standardSpriteRtl',
    utility: 'lightning.utilitySpriteRtl'
});

const defaultTokenValueMap = Object.assign(Object.create(null), {
    'lightning.actionSprite': '/assets/icons/action-sprite/svg/symbols.svg',
    'lightning.actionSpriteRtl': '/assets/icons/action-sprite/svg/symbols.svg',
    'lightning.customSprite': '/assets/icons/custom-sprite/svg/symbols.svg',
    'lightning.customSpriteRtl': '/assets/icons/custom-sprite/svg/symbols.svg',
    'lightning.doctypeSprite': '/assets/icons/doctype-sprite/svg/symbols.svg',
    'lightning.doctypeSpriteRtl': '/assets/icons/doctype-sprite/svg/symbols.svg',
    'lightning.standardSprite': '/assets/icons/standard-sprite/svg/symbols.svg',
    'lightning.standardSpriteRtl': '/assets/icons/standard-sprite/svg/symbols.svg',
    'lightning.utilitySprite': '/assets/icons/utility-sprite/svg/symbols.svg',
    'lightning.utilitySpriteRtl': '/assets/icons/utility-sprite/svg/symbols.svg'
});

function getBaseIconPath(category, direction) {
    const nameMap = direction === 'rtl' ? tokenNameMapRtl : tokenNameMap;
    return getToken(nameMap[category]) || getDefaultBaseIconPath(category, nameMap);
}

function getDefaultBaseIconPath(category, nameMap) {
    return defaultTokenValueMap[nameMap[category]];
}

function isIframeInEdge() {
    const isEdgeUA = /\bEdge\/.(\d+)\b/.test(navigator.userAgent);
    const inIframe = window.top !== window.self;
    return isEdgeUA && inIframe;
}

const proto = {
    add(className) {
        if (typeof className === 'string') {
            this[className] = true;
        } else {
            Object.assign(this, className);
        }
        return this;
    },
    invert() {
        Object.keys(this).forEach((key) => {
            this[key] = !this[key];
        });
        return this;
    },
    toString() {
        return Object.keys(this)
            .filter((key) => this[key])
            .join(' ');
    }
};

function classSet(config) {
    if (typeof config === 'string') {
        const key = config;
        config = {};
        config[key] = true;
    }
    return Object.assign(Object.create(proto), config);
}