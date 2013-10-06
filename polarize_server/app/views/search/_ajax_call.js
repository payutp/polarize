<script type="text/javascript">
$(function() {

    var query = "<%= @query %>";

    $(".bigtopic").html(query);

    $.get('/search_query/access_url.json', {t: query}, function(data) {
        $("#progressbar").progressbar("destroy");
        $( ".progress-label" ).text('');
        for (var cat in ['positive', 'negative']) {
            var prefix = cat.substring(0, 3);
            var responds = data[prefix];
            for (var obj in responds) {
                $('#' + prefix + 'sentence').html(responds['sentence']);
                $('#' + prefix + 'link').html(responds['title']);
                $('#' + prefix + 'link').attr('href', respnds['url']);
                if (responds['author']) {
                    $('#' + prefix + 'author').html('&mdash;' + responds['author']);
                } else {
                    $('#' + prefix + 'author').html('');
                }
            }
        }
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