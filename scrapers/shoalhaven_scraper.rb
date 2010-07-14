require 'info_master_scraper'

class ShoalhavenScraper < InfoMasterScraper
  def applications(date)
    base_path = "http://www3.shoalhaven.nsw.gov.au/DES/modules/applicationmaster/"
    base_url = base_path + "default.aspx"
    raw_table_values(date, "#{base_url}?page=search", 1).map do |values|
      
      #TODO: Unlike some other councils who have the description on the search results page, for this one you need to visit each item's page to get the description.

      da = DevelopmentApplication.new(
        :application_id => extract_application_id(values[1]),
        :date_received => extract_date_received(values[2]),
        :address => extract_address(values[3])
      )
      
      da.info_url = URI.escape(base_path + extract_info_url(values[0]))
      da.comment_url = da.info_url
      da
    end
  end
end