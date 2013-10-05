var BASE_URL = 'http://access.alchemyapi.com/calls';
var API_KEY = '61cc00a7028c5f89e4844f7958d51cfef45a92eb';
var ENDPOINTS = {};

ENDPOINTS['sentiment'] = {};
ENDPOINTS['sentiment']['url'] = '/url/URLGetTextSentiment';
ENDPOINTS['sentiment']['text'] = '/text/TextGetTextSentiment';
ENDPOINTS['sentiment']['html'] = '/html/HTMLGetTextSentiment';
ENDPOINTS['sentiment_targeted'] = {};
ENDPOINTS['sentiment_targeted']['url'] = '/url/URLGetTargetedSentiment';
ENDPOINTS['sentiment_targeted']['text'] = '/text/TextGetTargetedSentiment';
ENDPOINTS['sentiment_targeted']['html'] = '/html/HTMLGetTargetedSentiment';
ENDPOINTS['author'] = {};
ENDPOINTS['author']['url'] = '/url/URLGetAuthor';
ENDPOINTS['author']['html'] = '/html/HTMLGetAuthor';
ENDPOINTS['keywords'] = {};
ENDPOINTS['keywords']['url'] = '/url/URLGetRankedKeywords';
ENDPOINTS['keywords']['text'] = '/text/TextGetRankedKeywords';
ENDPOINTS['keywords']['html'] = '/html/HTMLGetRankedKeywords';
ENDPOINTS['concepts'] = {};
ENDPOINTS['concepts']['url'] = '/url/URLGetRankedConcepts';
ENDPOINTS['concepts']['text'] = '/text/TextGetRankedConcepts';
ENDPOINTS['concepts']['html'] = '/html/HTMLGetRankedConcepts';
ENDPOINTS['entities'] = {};
ENDPOINTS['entities']['url'] = '/url/URLGetRankedNamedEntities';
ENDPOINTS['entities']['text'] = '/text/TextGetRankedNamedEntities';
ENDPOINTS['entities']['html'] = '/html/HTMLGetRankedNamedEntities';
ENDPOINTS['category'] = {};
ENDPOINTS['category']['url']  = '/url/URLGetCategory';
ENDPOINTS['category']['text'] = '/text/TextGetCategory';
ENDPOINTS['category']['html'] = '/html/HTMLGetCategory';
ENDPOINTS['relations'] = {};
ENDPOINTS['relations']['url']  = '/url/URLGetRelations';
ENDPOINTS['relations']['text'] = '/text/TextGetRelations';
ENDPOINTS['relations']['html'] = '/html/HTMLGetRelations';
ENDPOINTS['language'] = {};
ENDPOINTS['language']['url']  = '/url/URLGetLanguage';
ENDPOINTS['language']['text'] = '/text/TextGetLanguage';
ENDPOINTS['language']['html'] = '/html/HTMLGetLanguage';
ENDPOINTS['text_clean'] = {};
ENDPOINTS['text_clean']['url']  = '/url/URLGetText';
ENDPOINTS['text_clean']['html'] = '/html/HTMLGetText';
ENDPOINTS['text_raw'] = {};
ENDPOINTS['text_raw']['url']  = '/url/URLGetRawText';
ENDPOINTS['text_raw']['html'] = '/html/HTMLGetRawText';
ENDPOINTS['text_title'] = {};
ENDPOINTS['text_title']['url']  = '/url/URLGetTitle';
ENDPOINTS['text_title']['html'] = '/html/HTMLGetTitle';
ENDPOINTS['feeds'] = {};
ENDPOINTS['feeds']['url']  = '/url/URLGetFeedLinks';
ENDPOINTS['feeds']['html'] = '/html/HTMLGetFeedLinks';
ENDPOINTS['microformats'] = {};
ENDPOINTS['microformats']['url']  = '/url/URLGetMicroformatData';
ENDPOINTS['microformats']['html'] = '/html/HTMLGetMicroformatData';

function generate_url(firstkey, secondkey, args) {
    var url = BASE_URL + ENDPOINTS[firstkey][secondkey] + '?apikey=' + API_KEY;

    for (var i = 0 ; i < args.length ; i ++) {
		if (i == 0) {
		    url += '&';
		}
		url += args[i][0] + '=' + args[i][1];
		if (i != args.length - 1) {
	    	url += '&';
		}
    }
    
    return url;
}

function ajax_alchemy(firstkey, secondkey, args, after_call) {
	var url = generate_url(firstkey, secondkey, args);

	$.ajax({
		url: url,
	})
	.done(after_call);
}
