/**
 *  Note: without sharing and global since we want to expose this functionality
 *  for suscriber usage regardless of their permissions
 */
global without sharing class DeleteUnusedLicenses {
    global void execute() {
        delete new CopadoLicensesSelector().unused();
    }
}