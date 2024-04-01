/**
 * validateCredential function is an utility component to check the validity of any org credential.
 * Input parameter :
 *     1. credentialId = org credentialId
 * Output : 1. sample output =>[{keyNumber : 1, message : 'message', validationType : 'OK'}]
 *          2. possible values for validationType =  OK, NON_SALESFORCE_CRED, ADD_AUTHENTICATION, WRONG_CREDENTIAL, CUSTOMER_ORG_NOT_EXISTS, CUSTOMER_ORG_NOT_VALIDATED
 */

import validate from '@salesforce/apex/CopadoCredentialValidatorCtrl.validate';
const validateCredential = async (credentialId) => await validate({ credentialId: credentialId });
export { validateCredential };