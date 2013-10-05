$(function() {

    $("#b1").click(function() {
        get_url($("#query").val());
        
    });

    var get_url = function(text) {
        var strings = text.split(" ");
        var url = "https://api.datamarket.azure.com/Bing/SearchWeb/v1/Web?format=json&Query=%27";
        for (s in strings) {
            url = url + strings[s];
        }
        url = url + "%27";
        var out;

        $.getJSON(url + "&callback=?", null, function(data) {
            //$("#test").text(data);
            alert("x");
        });
    };

});