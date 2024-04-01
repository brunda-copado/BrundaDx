/**
 * Created by jgaviria@copado.com
 * This will be executed in the Post Install Script
 * And will be refreshing the ScratchOrg Status and Cleaning the Attachments that are not needed
 */

    global class SfdxSchedulable implements Schedulable {



    public static String JOB_NAME = 'Copado DX Schedulable';
    // Every Day at 1am
    public static String CRON_EXP = '0 0 1 1/1 * ? *';

    global void execute(SchedulableContext ctx) {
        SfdxAPI.refreshStatus();
    }
}