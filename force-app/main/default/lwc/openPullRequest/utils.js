export function generatePullRequestUrl(config) {
    let path;
    const type = config.type;
    const url = config.url;

    if (type === 'Github' || type === 'Copado Version Control') {
        path = gitHubURL(config.base, config.compare);
    } else if (type === 'GitLab') {
        path = gitLabURL(config.base, config.compare);
    } else if (type === 'Bitbucket') {
        path = bitBucketURL(config.base, config.compare);
    } else if (type === 'Microsoft Team Service') {
        path = microsoftURL(config.base, config.compare);
    } else if (type === 'Others') {
        return otherURL(url, config.base, config.compare);
    }

    return url.endsWith('/') ? url + encodeURI(path) : url + '/' + encodeURI(path);
}

function gitHubURL(base, compare) {
    return 'compare/' + base + '...' + compare + '?expand=1';
}

function gitLabURL(base, compare) {
    return 'merge_requests/new?merge_request[source_branch]=' + compare + '&merge_request[target_branch]=' + base;
}

function bitBucketURL(base, compare) {
    return 'pull-requests/new?source=' + compare + '&dest=' + base + '&event_source=branch_detail';
}

function microsoftURL(target, source) {
    return 'Pullrequestcreate?targetRef=' + target + '&sourceRef=' + source;
}

function otherURL(url, target, source) {
    var targetKey = '[TARGET_BRANCH_NAME]',
        targetFound = false;
    var sourceKey = '[SOURCE_BRANCH_NAME]',
        sourceFound = false;

    if (url) {
        const myRegexp = /\[\s*?(\S*?)\s*?\]/g;
        let t;
        while ((t = myRegexp.exec(url))) {
            if (t[0] === targetKey) {
                targetFound = true;
            } else if (t[0] === sourceKey) {
                sourceFound = true;
            } else {
                console.warn('Unknown merge value in pull request base url : ', t[0]);
            }
        }
        if (sourceFound && targetFound) {
            return url.replace(targetKey, encodeURI(target)).replace(sourceKey, encodeURI(source));
        }
    }
    return '';
}