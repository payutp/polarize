require 'uri'
require 'open-uri'
require 'nokogiri'
require 'open_uri_redirections'
require 'thread'
require 'set'
require 'json'

class SearchQueryController < ApplicationController
    def access_url

        search_resulted_urls = search_from_google(3, params[:t])
        print 1
        absolute_urls = follow_relative_urls(search_resulted_urls)
        print 2
        alchemy_infomation = find_alchemy_infomation(absolute_urls, params[:t])
        print 3

        sentences = find_topic_sentences(alchemy_infomation)
        alchemy_infomation.each_with_index do |alif, ind|
            alif['sentence'] = sentences[ind]
        end

        respond_to do |format|
            format.json {render :json => alchemy_infomation.to_json}
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
                begin
                    if i == 0
                        url = 'http://google.com/search?q='
                    else
                        url = 'http://google.com/search?start=' + (10 * i).to_s + '&q='
                    end

                    tmp = strings.join("+")
                    url = url + tmp

                    doc = Nokogiri::HTML(open(url, :read_timeout => 10))

                    mutex_instance.synchronize do
                        doc.css('h3.r a.l', '//h3/a').each do |link|
                            if !link['href'].start_with?('http')
                                search_resulted_urls.push("http://google.com" + link['href'])
                            else
                                search_resulted_urls.push(link['href'])
                            end
                        end
                    end
                rescue Timeout::Error
                    p "Timeout search from google: " + url
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
                begin
                    doc = open(search_resulted_url, :allow_redirections => :all, :read_timeout => 10)

                    if doc.base_uri.query == nil
                        query = ''
                    else
                        query = '?' + doc.base_uri.query
                    end
                    uri = URI.escape(doc.base_uri.scheme + "://" + doc.base_uri.host + doc.base_uri.path + query)
                    mutex_instance.synchronize do
                        absolute_urls.push(uri)
                    end
                rescue Timeout::Error
                    p "Timeout Follow Relative URLs: " + search_resulted_url
                rescue Exception => e
                    p "Error " + e + " Follow Relative URLs: " + search_resulted_url
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        return absolute_urls.uniq
    end

    def find_alchemy_infomation(urls, keyword)
        alchemy_base_path = 'http://access.alchemyapi.com/calls/url/';
        global_args = '?apikey=61cc00a7028c5f89e4844f7958d51cfef45a92eb&outputMode=json';

        target_sentiment_app = 'URLGetTargetedSentiment'
        keyword_app = 'URLGetRankedKeywords'
        author_app = 'URLGetAuthor'
        title_app = 'URLGetTitle'

        target_sentiment_args = '&showSourceText=1&target=' + keyword
        keyword_args = '&sentiment=1'
        author_args = ''
        title_args = ''

        mutex_sentiment = Mutex.new
        mutex_keyword = Mutex.new
        mutex_author = Mutex.new
        mutex_title = Mutex.new

        threads = []

        fulltexts_raw = []
        keywords_raw = []
        authors_raw = []
        titles_raw = []

        urls.each_with_index do |url, ind|
            thread = Thread.new do
                begin
                    alchemy_api_url = alchemy_base_path + target_sentiment_app + global_args + target_sentiment_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_sentiment.synchronize do
                        fulltexts_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Targeted Sentiment: " + url
                end
            end
            threads.push thread
        end

        urls.each_with_index do |url, ind|
            thread = Thread.new do
                begin
                    alchemy_api_url = alchemy_base_path + keyword_app + global_args + keyword_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_keyword.synchronize do
                        keywords_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Keyword: " + url
                end
            end
            threads.push thread
        end

        urls.each_with_index do |url, ind|
            thread = Thread.new do
                begin
                    alchemy_api_url = alchemy_base_path + author_app + global_args + author_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_author.synchronize do
                        authors_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Author: " + url
                end
            end
            threads.push thread
        end

        urls.each_with_index do |url, ind|
            thread = Thread.new do
                begin
                    alchemy_api_url = alchemy_base_path + title_app + global_args + title_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_title.synchronize do
                        titles_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Title: " + url
                end
            end
            threads.push thread
        end

        threads.each do |thread|
            thread.join()
        end

        alchemy_infomation = []

        urls.each_with_index do |url, ind|
            if fulltexts_raw[ind] == nil || keywords_raw[ind] == nil ||
               authors_raw[ind] == nil || titles_raw[ind] == nil ||
               fulltexts_raw[ind]['status'] != 'OK' || keywords_raw[ind]['status'] != 'OK' ||
               authors_raw[ind]['status'] != 'OK' || titles_raw[ind]['status'] != 'OK'
                next
            end

            if fulltexts_raw[ind]['docSentiment']['type'] == 'neutral'
                fulltexts_raw[ind]['docSentiment']['score'] = 0
            end

            keywords_raw[ind]['keywords'].each do |keyword|
                if keyword['sentiment']['type'] == 'neutral'
                    keyword['sentiment']['score'] = 0
                end
            end

            alchemy_infomation.push({
                'score' => fulltexts_raw[ind]['docSentiment']['score'],
                'url' => url,
                'text' => fulltexts_raw[ind]['text'],
                'author' => authors_raw[ind]['author'],
                'title' => titles_raw[ind]['title'],
                'keywords' => keywords_raw[ind]['keywords'],
            })
        end

        alchemy_infomation = alchemy_infomation.sort_by{|obj| obj['score'].to_f}

        return alchemy_infomation
    end

    def find_keyword(urls, keyword)
        alchemy_sentimental_base_path = 'http://access.alchemyapi.com/calls/url/URLGetTargetedSentiment';
        global_args = '?apikey=61cc00a7028c5f89e4844f7958d51cfef45a92eb&outputMode=json&showSourceText=1&target=' + keyword;

        mutex_instance = Mutex.new
        threads = []

        fulltexts_raw = []

        urls.each_with_index do |url, ind|
            threads[ind] = Thread.new do
                begin
                    alchemy_api_url = alchemy_sentimental_base_path + global_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_instance.synchronize do
                        fulltexts_raw.push(doc)
                    end
                rescue Timeout::Error
                    p "Timeout Targeted Sentiment: " + url
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

    @@abbreviations = Set.new ["abbr.","abr.","acad.","adj.","adm.","adv.","agr.",
        "agri.","agric.","anon.","app.","approx.","assn.","b.","bact.","bap.","bib.",
        "bibliog.","biog.","biol.","bk.","bkg.","bldg.","blvd.","bot.","bp.","brig.",
        "brig.","gen.","bro.","bur.","c.a.","cal.","cap.","capt.","cath.","cc.","c.c.",
        "cent.","cf.","ch.","chap.","chem.","chm.","chron.","cir.","/circ.","cit.",
        "civ.","clk.","cm.","co.","c.o.","c.o.d.","col.","colloq.","com.","comdr.",
        "comr.","comp.","con.","cond.","conf.","cong.","consol.","constr.","cont.",
        "cont.","contd.","corp.","cp.","cpl.","cr.","crit.","ct.","cu.","cwt.","d.",
        "d.","dec.","def.","deg.","dep.","dept.","der.","deriv.","diag.","dial.",
        "dict.","dim.","dipl.","dir.","disc.","dist.","distr.","div.","dm.","do.",
        "doc.","doz.","dpt.","dr.","d.t.","dup.","dupl.","dwt.","e.","ea.","eccl.",
        "eccles.","ecol.","econ.","ed.","e.g.","elec.","elect.","elev.","emp.","e.m.u.",
        "enc.","ency.","encyc.","encycl.","eng.","entom.","entomol.","esp.","est.","al.",
        "etc.","seq.","ex.","exch.","exec.","lib.","f.","fac.","fed.","fem.","ff.","fol.",
        "fig.","fin.","fl.","fn.","fr.","ft.","fwd.","g.","gall.","gaz.","gen.","geog.",
        "geol.","geom.","gloss.","gov.","govt.","gram.","hab.","corp.","her.","hist.",
        "hort.","ht.","ib.","ibid.","id.","i.e.","illus.","imp.","in.","inc.","loc.",
        "cit.","ins.","inst.","intl.","introd.","is.","jour.","jr.","jud.","k.",
        "kilo.","kt.","lab.","lang.","lat.","l.c.","lib.","lieut.","lt.","lit.",
        "ltd.","lon.","long.","m.","mach.","mag.","maj.","mas.","masc.","math.",
        "mdse.","mech.","med.","mem.","mfg.","mfr.","mg.","mgr.","misc.","ml.","mo.",
        "mod.","ms.","mss.","mt.","mts.","mus.","n.","narr.","natl.","nav.","n.b.",
        "n.d.","neg.","no.","seq.","n.p.","n.","pag.","obit.","obj.","op.","cit.",
        "orch.","orig.","oz.","abbrev.","p.","pp.","par.","pat.","/patd.","pct.",
        "p.d.","pen.","perf.","philos.","phys.","pl.","ppd.","pref.","prin.","prod.",
        "tem.","pron.","pseud.","psych.","psychol.","pt.","pub.","publ.","q.","qr.",
        "qt.","qtd.","ques.","quot.","r.b.i.","quot.","rec.","ref.","reg.","rel.",
        "rev.","riv.","rpt.","s.","sc.","sch.","sci.","sculp.","sec.","secy.","sec.",
        "sect.","ser.","serg.","sergt.","sgt.","sing.","sol.","sp.","sq.","sub.",
        "subj.","sup.","supt.","surg.","sym.","syn.","t.","tbs.","tbsp.","tel.",
        "temp.","terr.","theol.","topog.","trans.","tr.","treas.","trig.","trigon.",
        "tsp.","twp.","ult.","univ.","usu.","v.","var.","vb.","vers.","vet.","viz.",
        "vet.","vol.","vox.","pop.","v.p.","vs.","v.","vs.","vss.","v.s.","writ."]

    def sentence_segmentation(text)
        segemented_sentences = []
        sentence = []
        word = []
        start = 0
        count = 0
        text.each_char do |c|
            if c.ord >= 33 && c.ord <= 126
                count = 0
                word.push c
            else
                count += 1
                if count > 3 && sentence.length > 0
                    if sentence.length > 5
                        segemented_sentences.push sentence.join(' ')
                    end
                    sentence = []
                end
                if word.length > 0
                    word = word.join()
                    sentence.push word
                    if ((word[-1] == '.' || word[-1] == '!' || word[-1] == '?') &&
                        word.length > 3 && word[-2] != '.' && word[-3] != '.' &&
                        !@@abbreviations.include?(word.downcase))
                        if sentence.length > 5
                            segemented_sentences.push sentence.join(' ')
                        end
                        sentence = []
                    end
                    word = []
                end
            end
        end
        if word.length > 0
            sentence.push word
            word = []
        end
        if sentence.length > 0
            segemented_sentences.push sentence.join(' ')
            sentence = []
        end
        return segemented_sentences
    end

    def find_topic_sentences(alchemy_infomation)
        mutex_instance = Mutex.new
        threads = []
        topic_sentences = []

        alchemy_infomation.each_with_index do |alif, ind|
            threads[ind] = Thread.new do
                segmented_sentences = sentence_segmentation(alif['text'])

                mutex_instance.synchronize do
                    # szu-po should select base on sentiment instead of returning the first one
                    topic_sentences[ind] = segmented_sentences[0]
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        return topic_sentences
    end

end
