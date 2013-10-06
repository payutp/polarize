require 'open-uri'
require 'nokogiri'

class SearchQueryController < ApplicationController    
     def access_url
        text = params[:t]
        strings = text.split
        puts text
        url = 'http://google.com/search?q='

        for s in strings
            url = url + s + "+"
        end
        if strings.length >= 1
            url = url[0..url.length-2]
        end

        doc = Nokogiri::HTML(open(url))
        ret = []

        doc.css('h3.r a.l', '//h3/a').each do |link|
            ret.push("http://google.com" + link['href'])
        end
        respond_to do |format|
            format.json {render :json => ret.to_json}
            format.all {render :text => "Only JSON supported at the moment"}
        end
     end
end
