require 'uri'
require 'open-uri'
require 'nokogiri'
require 'open_uri_redirections'
require 'thread'
require 'json'

class SearchQueryController < ApplicationController    
     def access_url

        search_resulted_urls = search_from_google(3, params[:t])

        absolute_urls = follow_relative_urls(search_resulted_urls)

        fulltexts_with_score = find_targeted_sentiment(absolute_urls, params[:t])

        respond_to do |format|
            format.json {render :json => fulltexts_with_score.to_json}
            format.all {render :text => "Only JSON supported at the moment"}
        end
     end

     def search_from_google(num_pages, query_text)
        search_resulted_urls = []

        mutex_instance = Mutex.new
        threads = []

        text = query_text
        strings = text.split

        num_pages.times do |i|
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
                        if !link['href'].start_with?('http')
                            search_resulted_urls.push("http://google.com" + link['href'])
                        else
                            search_resulted_urls.push(link['href'])
                        end
                    end
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        return search_resulted_urls.uniq
     end

     def follow_relative_urls(search_resulted_urls)
        mutex_instance = Mutex.new
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

        return absolute_urls.uniq
     end

     def find_targeted_sentiment(urls, keyword)
        alchemy_sentimental_base_path = 'http://access.alchemyapi.com/calls/url/URLGetTargetedSentiment';
        global_args = '?apikey=61cc00a7028c5f89e4844f7958d51cfef45a92eb&outputMode=json&showSourceText=1&target=' + keyword;

        mutex_instance = Mutex.new
        threads = []

        fulltexts_raw = []

        urls.each_with_index do |url, ind|
            threads[ind] = Thread.new do

                alchemy_api_url = alchemy_sentimental_base_path + global_args + '&url=' + url
                doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all).read)

                mutex_instance.synchronize do
                    fulltexts_raw.push(doc)
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        fulltexts_with_score = []

        fulltexts_raw.each do |alchemy_ret|
            if alchemy_ret['status'] != 'OK'
                next
            end

            if alchemy_ret['docSentiment']['type'] == 'neutral'
                alchemy_ret['docSentiment']['score'] = 0
            end

            fulltexts_with_score.push({
                'score' => alchemy_ret['docSentiment']['score'],
                'url' => alchemy_ret['url'],
                'text' => alchemy_ret['text']
            })
        end

        fulltexts_with_score = fulltexts_with_score.sort_by{|obj| obj['score'].to_f}

        return fulltexts_with_score
     end
end
