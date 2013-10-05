$(function() {

    $("#b1").click(function() {
        get_url($("#query").val());
        
    });

    var get_url = function(text) {
        var strings = text.split(" ");
        var url = "http://www.google.com/search?q=";
        for (s in strings) {
            url = url + strings[s];
        }

        var out;

        $.get(url, {}, function(data) {
            $("#test").text(data);
            alert("x");
        })
    };

});