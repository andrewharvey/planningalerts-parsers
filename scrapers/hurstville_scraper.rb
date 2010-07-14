require 'info_master_scraper'

#TODO: The default is 10 search results per page. Subsequent pages are requested with an AJAX request. Currently we only grab the 1st page.
#Could try POST'ing ctl00$cphContent$ctl01$ctl00$RadGrid1$ctl00$ctl03$ctl01$PageSizeComboBox=1000

class HurstvilleScraper < InfoMasterScraper
  def get_page(date, url)
    page = agent.get(url)
    
    # Click the Ok button on the form
    form = page.forms.first
    form.submit(form.button_with(:name => /btnOk|Yes|Button1|Agree/))

    # Get the page again
    page = agent.get(url)
    
=begin
    #Trying to submit the form using Mechanize didn't work. I suspect that it needs to execute some javascript to work.
    #So instead we just hardcode the GET paramaters into the request
    search_form = page.forms.first
    
    #From: ctl00_cphContent_ctl00_ctl03_dateInput_text
    #  To: ctl00_cphContent_ctl00_ctl05_dateInput_text
    search_form[search_form.field_with(:name => /ctl03_dateInput_text/).name] = "#{date.day}/#{date.month}/#{date.year}"
    search_form[search_form.field_with(:name => /ctl05_dateInput_text/).name] = "#{date.day}/#{date.month}/#{date.year}"
    search_form[search_form.field_with(:name => /ctl00\$cphContent\$ctl00\$ctl03/).name] = "#{date.year}-#{date.month}-#{date.day}"
    search_form[search_form.field_with(:name => /ctl00\$cphContent\$ctl00\$ctl03\$dateInput/).name] = "#{date.year}-#{date.month}-#{date.day}-00-00-00"
    search_form[search_form.field_with(:name => /ctl00\$cphContent\$ctl00\$ctl05/).name] = "#{date.year}-#{date.month}-#{date.day}"
    search_form[search_form.field_with(:name => /ctl00\$cphContent\$ctl00\$ctl05\$dateInput/).name] = "#{date.year}-#{date.month}-#{date.day}-00-00-00"
    
    search_form.submit(search_form.button_with(:name => /btnSearch|SearchBtn/))
=end
  end

  def remove_lot_sec_dp(address)
    #Lot # Sec # (SP|DP) #
    #but those #'s could be numbers or letters, but we don't want to start removing the suburb either

    #Examples
    #Lot 39 SP7474
    #Lot A DP327934
    #Lot 1 DP210009
    #Lot 3 Sec 14 DP12082
    #Lot 39 SP7474

    address.gsub(/ (Lot)? ?(\d*|\w (DP|SP))? ?(Sec)? ?\d* (SP|DP)? ?\d*/i, "")
  end
  
  def applications(date)
    base_path = "http://onlineservices.hurstville.nsw.gov.au/MasterViewLive/modules/applicationmaster/"
    base_url = base_path + "default.aspx"
    types = "DA" #for all use "DA,CC,CD,DAR,TR,TP,TRR,DAE"
    raw_table_values(date, "#{base_url}?page=found&1=#{date.day}/#{date.month}/#{date.year}&2=#{date.day}/#{date.month}/#{date.year}&4a=#{types}", 2, 'table', 0).map do |values| #remove the first two rows, as the footer gets listed as the second row by the HTML parser
      #4a options are,
      #Development Application, DA
      #Construction Certificates, CC
      #Complying Development, CD
      #Section 82A, DAR
      #Tree Removal, TR
      #Tree Pruning, TP
      #Tree Removal Review, TRR
      #DA Extended 1 Year, DAE
      
      #Example description column in applications listing (when page=foundDetails):
      #NUM ROAD [LOT [SEC] DP] SUBURB
      #DESCRIPTION TEXT
      
      da = DevelopmentApplication.new(
        :application_id => extract_application_id(values[1]),
        :date_received => extract_date_received(values[2]),
        :address => remove_lot_sec_dp(extract_address(values[3])),
        :description => extract_description(values[3])
      )
      
      da.info_url = URI.escape(base_path + extract_info_url(values[0]))
      da.comment_url = da.info_url
      da
    end
  end
end