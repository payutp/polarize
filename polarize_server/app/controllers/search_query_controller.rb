require 'uri'
require 'open-uri'
require 'nokogiri'
require 'open_uri_redirections'
require 'thread'

class SearchQueryController < ApplicationController    
     def access_url

        pages_google = 3

        search_resulted_urls = []

        mutex_instance = Mutex.new
        threads = []

        text = params[:t]
        strings = text.split

        pages_google.times do |i|
            threads[i] = Thread.new do
                if i == 0
                    url = 'http://google.com/search?q='
                else
                    url = 'http://google.com/search?start=' + (10 * i).to_s + '&q='
                end

                tmp = strings.join("+")
                url = url + tmp

                doc = Nokogiri::HTML(open(url))
                
                mutex_instance.synchronize do
                    doc.css('h3.r a.l', '//h3/a').each do |link|
                        if
                            search_resulted_urls.push("http://google.com" + link['href'])
                        end
                        # Pasin: I believe that the link below is adv but I'm not sure.
                        %%if link['href'][0..3] == "http"
                            search_resulted_urls.push(link['href'])
                        end%
                    end
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        absolute_urls = []
        threads = []
        search_resulted_urls.each_with_index do |search_resulted_url, ind|
            threads[ind] = Thread.new do
                doc = open(search_resulted_url, :allow_redirections => :all)
                if doc.base_uri.query == nil
                    query = ''
                else
                    query = '?' + doc.base_uri.query
                end
                uri = URI.escape(doc.base_uri.scheme + "://" + doc.base_uri.host + doc.base_uri.path + query)
                mutex_instance.synchronize do
                    absolute_urls.push(uri)
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        respond_to do |format|
            format.json {render :json => absolute_urls.to_json}
            format.all {render :text => "Only JSON supported at the moment"}
        end
     end
end
