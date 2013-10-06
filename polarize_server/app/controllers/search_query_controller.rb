require 'open-uri'
require 'nokogiri'

class SearchQueryController < ApplicationController    
     def access_url
        text = params[:t]
        strings = text.split
        url = 'http://google.com/search?q='

        tmp = strings.join("+")
        url = url + tmp

        doc = Nokogiri::HTML(open(url))
        ret = []

        doc.css('h3.r a.l', '//h3/a').each do |link|
            if link['href'][0..3] == "http"
                ret.push(link['href'])
            else
                ret.push("http://google.com" + link['href'])
            end
        end
        respond_to do |format|
            format.json {render :json => ret.to_json}
            format.all {render :text => "Only JSON supported at the moment"}
        end
     end
end
