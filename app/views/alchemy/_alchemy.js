<script type="text/javascript">
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
    var url = BASE_URL + ENDPOINTS[firstkey][secondkey] + '?apikey=' + API_KEY + '&outputMode=json';

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
    $.get(generate_url(firstkey, secondkey, args), after_call);
}

var count, expected_total_count;
var url_info, best, worst;
var CUT_LENGTH = 100;
var NUM_FOR = 10, NUM_AGAINST = 10;

function format_output_text(text) {
    var text2 = text;
    //var text2 = escape(text);
    // remove all the goddamn special characters from the string
    text2 = text2.replace(/[^a-zA-Z ]/g, '');

    if (text2.length > CUT_LENGTH) {
        i = CUT_LENGTH - 1;
        while (text2.charAt(i) == ' ') {
            i --;
        }
        text2 = text2.substring(0, i + 1);
    }

    return text2;
}

function finish_fetch_score(data) {
    count ++;
    document.getElementById("test_result_for").innerHTML = 'Count : ' + count.toString();

    if (data.status == 'OK') {
        var score;
        if (data.docSentiment.type != 'neutral') {
            score = data.docSentiment.score
        } else {
            score = 0;
        }
        var text = format_output_text(data.text);
        var url = data.url;

        url_info.push({
            'score': score,
            'text': text,
            'url': url,
        });

        if (count == expected_total_count) {
            document.getElementById("test_result_for").innerHTML = 'Count = expected_total_count = ' + count.toString();

            var num_best, num_worst;
            
            if (url_info.length >= NUM_FOR + NUM_AGAINST) {
                num_best = NUM_FOR;
                num_worst = NUM_AGAINST;
            } else {
                num_best = (url_info.length + 1) / 2;
                num_worst = url_info.length - num_best;
            }
            
            url_info.sort(
                function(obj1, obj2) {
                    return obj2.score - obj1.score;
            });

            best = url_info.slice(0, num_best);
            worst = url_info.slice(url_info.length - num_worst, url_info.length);

            // FOR TESTING ONLY
            document.getElementById("test_result_for").innerHTML = JSON.stringify(best);
            document.getElementById("test_result_against").innerHTML = JSON.stringify(worst);
        }
    }
}

function get_targeted_sentimental(urls, word) {

    count = 0;
    url_info = [];
    // For each url, need to fetch score
    expected_total_count = urls.length;

    for (var i = 0 ; i < urls.length ; i ++) {
        ajax_alchemy(
            'sentiment_targeted',
            'url',
            [
                ['showSourceText', '1'],
                ['target', 'ObamaCare'],
                ['url', urls[i]],
            ],
            finish_fetch_score
            );
    }

    // count = 0;
    // For each url left, fetch summary
    // expected_total_count += Math.min(urls.length, NUM_FOR + NUM_AGAINST);
}
</script>