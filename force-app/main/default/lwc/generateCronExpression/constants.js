import GENERATE_CRON_EXPRESSION from '@salesforce/label/c.Generate_Cron_Expression';
import CREATE_CRON_EXPRESSION from '@salesforce/label/c.CREATE_CRON_EXPRESSION';
import CONFIGURE_PARAMETERS from '@salesforce/label/c.Configure_Parameters';
import REPEAT_EVERY from '@salesforce/label/c.Repeat_Every';
import STARTS_AT from '@salesforce/label/c.STARTS_AT';
import CANCEL from '@salesforce/label/c.Cancel';
import CRON_EXPRESSION_HOURS from '@salesforce/label/c.Cron_Expression_Hours';
import CRON_EXPRESSION_DAYS from '@salesforce/label/c.Cron_Expression_Days';
import CRON_EXPRESSION_WEEKS from '@salesforce/label/c.Cron_Expression_Weeks';
import SUNDAY from '@salesforce/label/c.SUNDAY';
import MONDAY from '@salesforce/label/c.MONDAY';
import TUESDAY from '@salesforce/label/c.TUESDAY';
import WEDNESDAY from '@salesforce/label/c.WEDNESDAY';
import THURSDAY from '@salesforce/label/c.THURSDAY';
import FRIDAY from '@salesforce/label/c.FRIDAY';
import SATURDAY from '@salesforce/label/c.SATURDAY';

export const label = {
    GENERATE_CRON_EXPRESSION,
    CREATE_CRON_EXPRESSION,
    CONFIGURE_PARAMETERS,
    REPEAT_EVERY,
    STARTS_AT,
    CANCEL
};

export const HOURS_VALUE = 'hours';
export const DAYS_VALUE = 'days';
export const WEEKS_VALUE = 'weeks';

export const timeFrameOptions = [
    { label: CRON_EXPRESSION_HOURS, value: HOURS_VALUE },
    { label: CRON_EXPRESSION_DAYS, value: DAYS_VALUE },
    { label: CRON_EXPRESSION_WEEKS, value: WEEKS_VALUE }
];
export const daysOptions = [
    { label: MONDAY, value: '2' },
    { label: TUESDAY, value: '3' },
    { label: WEDNESDAY, value: '4' },
    { label: THURSDAY, value: '5' },
    { label: FRIDAY, value: '6' },
    { label: SATURDAY, value: '7' },
    { label: SUNDAY, value: '1' }
];