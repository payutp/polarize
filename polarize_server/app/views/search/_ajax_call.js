<script type="text/javascript">
$(function() {

    var query = "<%= @query %>";

    $(".bigtopic").html(query);

    $.get('/search_query/access_url.json', {t: query}, function(raw_data) {
        $("#result_test").html(raw_data);

        //var data = JSON.parse(raw_data);
        var data = raw_data;

        $("#progressbar").progressbar("destroy");
        $(".progress-label").text('');
        $("#result_test").html(data);
        console.log(data);
        cats = ['positive', 'negative'];
        for (var i = 0 ; i < 2 ; i ++) {
            var cat = cats[i];
            var prefix = cat.substring(0, 3);
            var responds = data[cat];
            console.log(responds);
            var ind = 0;
            for (var ind = 0 ; ind < responds.length ; ind ++) {
                obj = responds[ind];
                $('#' + prefix + 'sentence' + ind).html(obj['sentence']);
                $('#' + prefix + 'link' + ind).html(obj['title']);
                $('#' + prefix + 'link' + ind).attr('href', obj['url']);
                if (obj['author']) {
                    $('#' + prefix + 'author' + ind).html('&mdash;' + obj['author']);
                } else {
                    $('#' + prefix + 'author' + ind).html('');
                }
            }
        }
        $(".grid_6").css("visibility", "visible");
    });

    $("#result_test").html('Ajax sent. Waiting for result ...');

    $(function() {
        var progressbar = $("#progressbar");
        var progressLabel = $(".progress-label");
 
        progressbar.progressbar({
            value: false,
            change: function() {
                progressLabel.text( progressbar.progressbar("value") + "%" );
            },
            complete: function() {
                progressLabel.text("Complete!");
            }
        });
 
        //var count = 0;
        //function progress() {
        //    if (progressLabel.text() != '') {
        //        var val = progressbar.progressbar("value");
        //        count ++;

        //        if (count == 2) {
        //            val = 1;
        //        }

        //        if (val) {
        //            val ++;
        //            progressbar.progressbar("value", val);
        //        }

        //        if (!val || val < 99) {
        //            setTimeout(progress, 200);
        //        }
        //    }
        //}

        //setTimeout( progress, 3000 );
   });

});
</script>