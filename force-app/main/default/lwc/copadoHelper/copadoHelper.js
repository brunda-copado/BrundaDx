import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import STYLE from '@salesforce/resourceUrl/CopadoLightningCSS';
import Git_Repo_Helper_Text from '@salesforce/label/c.Git_Repo_Helper_Text';
import Git_Repository_Overview from '@salesforce/label/c.Git_Repository_Overview';
import HTTPS_vs_SSH_Authentication from '@salesforce/label/c.HTTPS_vs_SSH_Authentication';
import Connect_to_Git_Rep_by_firewall from '@salesforce/label/c.Connect_to_Git_Rep_by_firewall';

export default class CopadoHelper extends LightningElement {
label = {
        Git_Repo_Helper_Text,
        Git_Repository_Overview,
        HTTPS_vs_SSH_Authentication,
        Connect_to_Git_Rep_by_firewall
    };
    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, STYLE).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the styles")
        })
    }
}