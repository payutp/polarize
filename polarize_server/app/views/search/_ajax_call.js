<script type="text/javascript">
$(function() {

    var query = "<%= @query %>";

    $("#query_test").html('(Test) The query is ' + query + '.');

    $.get('/search_query/access_url.json', {t: query}, function(data) {
        $("#progressbar").progressbar("destroy");
        $( ".progress-label" ).text('');
        $("#result_test").html(JSON.stringify(data));
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
 
        var count = 0;
        function progress() {
            if (progressLabel.text() != '') {
                var val = progressbar.progressbar("value");
                count ++;

                if (count == 2) {
                    val = 1;
                }

                if (val) {
                    val ++;
                    progressbar.progressbar("value", val);
                }

                if (!val || val < 99) {
                    setTimeout(progress, 200);
                }
            }
        }

        setTimeout( progress, 3000 );
   });

});
</script>