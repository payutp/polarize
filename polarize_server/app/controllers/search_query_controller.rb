require 'uri'
require 'open-uri'
require 'nokogiri'
require 'open_uri_redirections'
require 'thread'
require 'set'

class SearchQueryController < ApplicationController
     def access_url

        search_resulted_urls = search_from_google(3, params[:t])

        absolute_urls = follow_relative_urls(search_resulted_urls)

        respond_to do |format|
            format.json {render :json => absolute_urls.to_json}
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

        return search_resulted_urls
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

        return absolute_urls
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

    def sentence_segmentation(text):
        sentences = []


        return sentences
    end
end
