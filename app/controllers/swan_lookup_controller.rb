require 'open-uri'
require 'uri'

class SwanLookupController < ApplicationController

  def index
    
  end
  
  def locations
    # TODO: return a list of all locations
  end
  
  def search
    encoded_query = URI.escape(params[:query])
    
    # location -> location aliases
    # location: uid, name, lat/lng, address and whatnot
    # TODO search needs to have one of
    # - a lat/lng that can be resolved to a location
    # - a location id passed in (to be resolved to a location)
    
    # location = params[:location_id]
    
    # TODO: url should include location, instead of filtering after the fact
    url = 'http://swanencore.mls.lib.il.us/iii/encore/search/C%7CS'+ encoded_query + '%7CFf%3Afacetmediatype%3Ab%3Ab%3ABOOK%3A%3A%7COrightresult?lang=eng&suite=def'
    # http://swanencore.mls.lib.il.us/iii/encore/search/C%7CSthe+stand+stephen+king%7CFf%3Afacetmediatype%3Ab%3Ab%3ABOOK%3A%3A%7CFf%3Afacetcollections%3A164%3A164%3AOak%25252BPark%25252BMain%3A%3A%7COrightresult?lang=eng&suite=def
    # http://swanencore.mls.lib.il.us/iii/encore/search/C%7CSthe+stand+stephen+king%7CFf%3Afacetmediatype%3Ab%3Ab%3ABOOK%3A%3A%7CFf%3Afacetcollections%3A163%3A164%3AOak%25252BPark%25252BMain%3A%3A%7CFf%3Afacetcollections%3A57%3A57%3AFrankfort%3A%3A%7COrightresult?lang=eng&suite=def
    # print " - fetching: " + url + "\n"
    doc = Nokogiri::HTML(open(url))

    results = {
      :status => "OK",
      :message => "",
      :titles => []
    }
    if doc.to_s.include? "No catalog results found"
      results[:message] = "No results found"
    else
      b = doc.css('table.browseBibTable')
      foundTitle= b.css("div.dpBibTitle/a").first.text.strip()
      foundAuthor = b.css("div.dpBibTitle").children[4].text.strip()
      foundAuthor.sub!(/^\/ /,"")
  
      # for example:
      # doc = Nokogiri::HTML(open('http://swanencore.mls.lib.il.us/iii/encore/search/C%7CSMarguerite+Feitlowitz+A+Lexicon+of+Terror%3A+Argentina+and+the+Legacies+of+Torture%7COrightresult%7CU1?lang=eng&suite=def'))
      first_result = b.css("div.dpBibHoldingStatement")
      if first_result and first_result.css("span.callLocation").text().strip().include? "Oak Pk Main"
        results[:titles] << {
          :title => foundTitle, 
          :author => foundAuthor, 
          :location=> first_result.css("span.callNum").text().strip().gsub("\u00A0", ""), 
          :status => first_result.css("span.dpBibHoldingStatus").text().strip().gsub("\u00A0", "")
        }
      end
  
      available_table = b.css("table.itemTable")
  
      available_table.children.each do |row|
        cells = row.css("td")
        if cells.size >= 2 and (cells[0].text.include? "Oak Pk Main" or cells[0].text.include? "Oak Park Main")
          results[:titles] << {
            :title => foundTitle, 
            :author => foundAuthor, 
            :location=>cells[1].text.strip.gsub("\u00A0", ""), 
            :status => cells[2].text.strip.gsub("\u00A0", "")
          }
          # print " - found "+foundTitle + " ("+foundAuthor+"): " + cells[1].text.strip + cells[2].text.strip + "\n"
        end
      end
    end
    
    
    
    respond_to do |format|
      format.html
      format.json { render :json => results }
    end
  end
  
end
