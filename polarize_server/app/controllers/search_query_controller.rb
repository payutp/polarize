require 'uri'
require 'open-uri'
require 'nokogiri'
require 'open_uri_redirections'
require 'thread'
require 'set'
require 'json'

class SearchQueryController < ApplicationController
    @@vs_words = [' vs ', ' v.s ', ' v.s. ', ' versus ']
    def access_url
        vs = 0
        t1 = nil
        t2 = nil
        @@vs_words.each do |vs_word|
            pres = params[:t].downcase.index(vs_word)
            if pres != nil
                vs = 1
                t1 = params[:t][0, pres - 1]
                t2 = params[:t][pres - 1 + vs_word.length, params[:t].length - pres + 1 + vs_word.length]
            end
        end

        search_resulted_urls, titles = search_from_google(2, params[:t], vs, t1, t2)
        query = params[:t]
        print 1
        absolute_urls = follow_relative_urls(search_resulted_urls)
        print 2
        alchemy_infomation = find_alchemy_infomation(absolute_urls, params[:t], vs, titles, t1, t2)
        print 3

        sentences, topic_score = find_topic_sentences(alchemy_infomation, query)
        alchemy_infomation.each_with_index do |alif, ind|
            alif['sentence'] = sentences[ind]
            alif['topic_score'] = topic_score[ind]
        end

        alchemy_hash = {}
        filtered = []
        alchemy_infomation.each do |alif|
            if alchemy_hash.include?(alif['sentence'])
                next
            end
            alchemy_hash[alif['sentence']] = 1
            filtered.push alif
        end

        positive = []
        negative = []
        number = filtered.length / 2
        if number > 5
            number = 5
        end
        idx = 0
        while idx < number do
            positive.push ({
                'sentence' => filtered[-idx-1]['sentence'],
                'author' => filtered[-idx-1]['author'],
                'title' => filtered[-idx-1]['title'],
                'url' => filtered[-idx-1]['url'],
            })
            negative.push ({
                'sentence' => filtered[idx]['sentence'],
                'author' => filtered[idx]['author'],
                'title' => filtered[idx]['title'],
                'url' => filtered[idx]['url'],
            })
            idx += 1
        end

        response = {
            'positive' => positive,
            'negative' => negative
        }
        if vs != 0
            response['vs'] = 1
            response['t1'] = t1
            response['t2'] = t2
        else
            response['vs'] = 0
        end


        respond_to do |format|
            format.json {render :json => response.to_json}
            format.all {render :text => "Only JSON supported at the moment"}
        end
    end

    def search_from_google(num_pages, query_text, vs=0, t1=nil, t2=nil)
        search_resulted_urls = []

        mutex_instance = Mutex.new
        threads = []

        text = query_text
        strings = text.split

        if vs != 0
            t1 = t1.split.join('+')
            t2 = t2.split.join('+')
        end

        titles_hash = {}
        titles = []

        (num_pages + 2).times do |i|
            threads[i] = Thread.new do
                begin
                    tmp = strings.join("+")

                    if i == 0
                        if vs != 0
                            url = 'http://google.com/search?q=' + t1 + '+is+better+than+' + t2
                        else
                            url = 'http://google.com/search?q=' + tmp + '+is+good'
                        end
                    elsif i == 1
                        if vs != 0
                            url = 'http://google.com/search?q=' + t1 + '+is+worse+than+' + t2
                        else
                            url = 'http://google.com/search?q=' + tmp + '+is+good'
                        end
                    elsif i == 2
                        url = 'http://google.com/search?q=' + tmp
                    else
                        url = 'http://google.com/search?start=' + (10 * (i - 2)).to_s + '&q=' + tmp
                    end

                    doc = Nokogiri::HTML(open(url, :read_timeout => 10))

                    mutex_instance.synchronize do
                        doc.css('h3.r a').each do |link|
                            if !link['href'].start_with?('http')
                                search_url = "http://google.com" + link['href']
                            else
                                search_url = link['href']
                            end
                            title = link.content
                            if !titles_hash.include?(title)
                                search_resulted_urls.push(search_url)
                                titles.push(title)
                                titles_hash[title] = 1
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

        return search_resulted_urls, titles
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
                        absolute_urls[ind] = uri
                    end
                rescue Timeout::Error
                    p "Timeout Follow Relative URLs: " + search_resulted_url
                rescue Exception => e
                    p "Error " + e.to_s() + " Follow Relative URLs: " + search_resulted_url
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        return absolute_urls
    end

    def clean_keyword(keyword)
        cleaned = []
        keyword.each_char do | c |
            if c.ord >= 65 && c.ord <= 90 || c.ord >= 97 && c.ord <= 122 || c.ord >= 48 && c.ord <= 57
                cleaned.push c
            else
                cleaned.push ' '
            end
        end
        cleaned = cleaned.join().split
        leng = -1
        best = ''
        cleaned.each do |word|
            if word.length > leng
                leng = word.length
                best = word
            end
        end
        return best
    end

    def find_alchemy_infomation(urls, keyword, titles, vs=0, k1=nil, k2=nil)
        alchemy_base_path = 'http://access.alchemyapi.com/calls/url/'
        global_args = '?apikey=61cc00a7028c5f89e4844f7958d51cfef45a92eb&outputMode=json'

        target_sentiment_app = 'URLGetTargetedSentiment'
        keyword_app = 'URLGetRankedKeywords'
        author_app = 'URLGetAuthor'
        title_app = 'URLGetTitle'

        keyword_args = '&showSourceText=1&sentiment=1'
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
            if !url
                next
            end
            thread = Thread.new do
                begin
                    doc = nil
                    if vs != 0
                        target_sentiment_args = '&target=' + clean_keyword(keyword)
                        alchemy_api_url = alchemy_base_path + target_sentiment_app + global_args + target_sentiment_args + '&url=' + url
                        doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)
                    else
                        target_sentiment_args = '&target=' + clean_keyword(k1)
                        alchemy_api_url = alchemy_base_path + target_sentiment_app + global_args + target_sentiment_args + '&url=' + url
                        doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)
                        target_sentiment_args = '&target=' + clean_keyword(k2)
                        alchemy_api_url = alchemy_base_path + target_sentiment_app + global_args + target_sentiment_args + '&url=' + url
                        doc2 = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)
                        if doc["status"] == 'OK' && doc2["status"] == 'OK'
                            doc["score"] = (doc["score"].to_f() - doc2["score"].to_f()).to_s()
                        else
                            doc["status"] = 'ERROR'
                        end
                    end

                    mutex_sentiment.synchronize do
                        fulltexts_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Targeted Sentiment: " + url
                rescue Exception => e
                    p "Error " + e.to_s() + " Targeted Sentiment: " + url
                end
            end
            threads.push thread
        end

        urls.each_with_index do |url, ind|
            if !url
                next
            end
            thread = Thread.new do
                begin
                    alchemy_api_url = alchemy_base_path + keyword_app + global_args + keyword_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_keyword.synchronize do
                        keywords_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Keyword: " + url
                rescue Exception => e
                    p "Error " + e.to_s() + " Keyword: " + url
                end
            end
            threads.push thread
        end

        urls.each_with_index do |url, ind|
            if !url
                next
            end
            thread = Thread.new do
                begin
                    alchemy_api_url = alchemy_base_path + author_app + global_args + author_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_author.synchronize do
                        authors_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Author: " + url
                rescue Exception => e
                    p "Error " + e.to_s() + " Author: " + url
                end
            end
            threads.push thread
        end

        urls.each_with_index do |url, ind|
            if !url
                next
            end
            thread = Thread.new do
                begin
                    alchemy_api_url = alchemy_base_path + title_app + global_args + title_args + '&url=' + url
                    doc = JSON.parse(open(alchemy_api_url, :allow_redirections => :all, :read_timeout => 10).read)

                    mutex_title.synchronize do
                        titles_raw[ind] = doc
                    end
                rescue Timeout::Error
                    p "Timeout Title: " + url
                rescue Exception => e
                    p "Error " + e.to_s() + " Title: " + url
                end
            end
            threads.push thread
        end

        threads.each do |thread|
            thread.join()
        end

        alchemy_infomation = []

        urls.each_with_index do |url, ind|
            if !url
                next
            end
            if fulltexts_raw[ind] == nil || keywords_raw[ind] == nil ||
               authors_raw[ind] == nil || titles_raw[ind] == nil
                puts 'url0 : ' + url + ' failed.' + fulltexts_raw[ind].to_s() + ' ' +
                     keywords_raw[ind].to_s() + ' ' + authors_raw[ind].to_s() + ' ' +
                     titles_raw[ind].to_s()
                next
            end
            if authors_raw[ind]['status'] != 'OK'
                authors_raw[ind]['status'] = 'OK'
                authors_raw[ind]['author'] = ''
            end
            if titles_raw[ind]['status'] != 'OK'
                titles_raw[ind]['status'] = 'OK'
                titles_raw[ind]['title'] = titles[ind]
            end
            if fulltexts_raw[ind]['status'] != 'OK' || keywords_raw[ind]['status'] != 'OK'
                puts 'url : ' + url + ' failed.' + fulltexts_raw[ind]['status'] + ' ' +
                     keywords_raw[ind]['status']
                next
            end

            if fulltexts_raw[ind]['docSentiment']['type'] == 'neutral'
                fulltexts_raw[ind]['docSentiment']['score'] = '0'
            end

            keywords_raw[ind]['keywords'].each do |keyword|
                if keyword['sentiment']['type'] == 'neutral'
                    keyword['sentiment']['score'] = '0'
                end
            end

            alchemy_infomation.push({
                'score' => fulltexts_raw[ind]['docSentiment']['score'].to_f(),
                'url' => url,
                'text' => keywords_raw[ind]['text'],
                'author' => authors_raw[ind]['author'],
                'title' => titles_raw[ind]['title'],
                'keywords' => keywords_raw[ind]['keywords'],
            })
        end

        alchemy_infomation = alchemy_infomation.sort_by{|obj| obj['score']}

        return alchemy_infomation
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
                    segemented_sentences.push sentence
                    sentence = []
                end
                if word.length > 0
                    word = word.join()
                    sentence.push word
                    if ((word[-1] == '.' || word[-1] == '!' || word[-1] == '?') &&
                        word.length > 3 && word[-2] != '.' && word[-3] != '.' &&
                        !@@abbreviations.include?(word.downcase))
                        segemented_sentences.push sentence
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
            segemented_sentences.push sentence
            sentence = []
        end
        return segemented_sentences
    end

    def find_topic_sentences(alchemy_infomation, query)
        mutex_instance = Mutex.new
        threads = []
        topic_sentences = []
        topic_score = []

        alchemy_infomation.each_with_index do |alif, ind|
            threads[ind] = Thread.new do
                segmented_sentences = sentence_segmentation(alif['text'])

                keyword_inv = {}
                alif['keywords'].each_with_index do |keyword, idx|
                    keyword_inv[keyword['text'].downcase] = idx
                end

                relevance_sentences = []
                sentiment_sentences = []
                has_query_sentences = []
                segmented_sentences.each do |sentence|
                    relevance = 0.0
                    sentiment = 0.0
                    has_query = 0
                    st = 0
                    while st < sentence.length do
                        len = 1
                        while len <= 3 && st + len <= sentence.length do
                            word = sentence[st, len].join(' ').downcase

                            if keyword_inv.include?(word)
                                relevance += alif['keywords'][keyword_inv[word]]['relevance'].to_f()
                                sentiment += alif['keywords'][keyword_inv[word]]['sentiment']['score'].to_f().abs() **
                                             (1.0 / alif['keywords'][keyword_inv[word]]['relevance'].to_f())
                            end
                            if query.downcase == word
                                has_query = 1
                            end
                            len += 1
                        end
                        st += 1
                    end
                    relevance_sentences.push relevance
                    sentiment_sentences.push sentiment
                    has_query_sentences.push has_query
                end

                best_sentence = ''
                best_score = -10

                st = 0
                while st < segmented_sentences.length do
                    ed = st
                    word_count = 0
                    relevance = 0.0
                    sentiment = 0.0
                    has_query = 0
                    while ed < st + 3 && ed < segmented_sentences.length do
                        if segmented_sentences[ed].length < 5
                            break
                        end
                        word_count += segmented_sentences[ed].length
                        if word_count > 40
                            break
                        end
                        relevance += relevance_sentences[ed]
                        sentiment += sentiment_sentences[ed]
                        has_query += has_query_sentences[ed]
                        score = (relevance / word_count + 10 * sentiment / word_count) *
                                (1 - ((20 - word_count) / 15.0).abs())
                        if has_query > 0
                            score += 1
                        end
                        if score > best_score
                            best_score = score
                            best_sentence = segmented_sentences[st, ed - st + 1].flatten(1).join(' ')

                            #puts ind.to_s() + ': ' + st.to_s() + '-' + ed.to_s() + ' ' + score.to_s() + ' ' + best_sentence
                        end
                        ed += 1
                    end
                    st += 1
                end

                mutex_instance.synchronize do
                    topic_sentences[ind] = best_sentence
                    topic_score[ind] = best_score
                end
            end
        end

        threads.each do |thread|
            thread.join()
        end

        return topic_sentences, topic_score
    end

end
