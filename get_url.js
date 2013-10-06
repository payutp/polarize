$(function() {

    $("#b1").click(function() {
        get_url($("#query").val());
        
    });

    var get_url = function(text) {
        var strings = text.split(" ");
        var url = "https://9488a936-8230-401b-98c0-4af12fce56d2:mJ4truIiBsJCQkh01rfyR1rtIrmvw6Whcj+fO8SqmZI=@api.datamarket.azure.com/Bing/SearchWeb/v1/Web?Query=%27";
        for (s in strings) {
            url = url + strings[s] + "+";
        }
        url = url + "%27";
        var out;

/*
        $.ajax({
            url: url,
            dataType: 'jsonp',
            jsonp: 'jsonp',
            jsonpCallback: function(data) {alert("FUCK");}
        });*/
        $.get(url, null, function(data) {
            $("#test").text(data.text());
        });
    };

});