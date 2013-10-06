<script type="text/javascript">
$(function() {

    $("#b1").click(function() {
        get_urls($("#query").val());
        
    });

    var get_urls = function(text) {
        $.get("/search_query/access_url", {t : text}, function(data) {
            for(var s in data) {
                $("#test").append(data[s] + '</br>');
            }
        });
    };

});
</script>