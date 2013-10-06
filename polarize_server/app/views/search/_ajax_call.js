<script type="text/javascript">
$(function() {

    var query = "<%= @query %>";

    $("#query_test").html('(Test) The query is ' + query + '.');

    $.get('/search_query/access_url.json', {t: query}, function(data){
        $("#result_test").html(JSON.stringify(data));
    });

    $("#result_test").html('Ajax sent. Waiting for result ...');

});
</script>