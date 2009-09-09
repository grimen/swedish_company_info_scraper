require 'rubygems'
require 'scrubyt'
require 'nokogiri'

# == Usage:
#
# SwedishCompanyInfoScraper::AllaBolag.new("556608-0155", true).run
#
module SwedishCompanyInfoScraper
  
  class Person
    attr_accessor :first_name, :last_name
  end
  
  class Location
    attr_accessor :street_address, :postal_code, :city, :service_region, :country, :country_code
    def postal_address; "#{postal_code} #{city}"end
  end
  
  class Company
    attr_accessor :name, :orgnr, :owner, :visit_address, :mail_address, :mobile, :phone, :email, :website
    def initialize(orgnr)
      @orgnr = orgnr
    end
  end
  
  class AllaBolag
    
    attr_reader :company
    
    def initialize(orgnr, output_results = false)
      @orgnr = orgnr
      @output_results = output_results
    end
    
    def orgnr_format(orgnr)
      orgnr.gsub(/\W/, '')
    end
    
    def run
      @company = Company.new(@orgnr)
      raise "Org.nr for a company is not specified." if company.orgnr.blank?
      
      url = "http://allabolag.se/#{orgnr_format(company.orgnr)}"
      
      puts "\n========================================="
      puts "\nOrg.nr:"
      puts "  #{company.orgnr}"
      puts "URL:"
      puts "  #{url}"
      
      # Scrape company data from webpage
      company_record = scrape_webpage(url)
      
      # Parse company data from XML result
      company_hash = parse_xml(company_record)
      
      # Print resulting company data
      print_result(company_hash) if @output_results
      
      company_hash
    end
    
    def scrape_webpage(url)
      # Scrubyt.logger = Scrubyt::Logger.new
      
      company_record = Scrubyt::Extractor.define do
        fetch(url)
        
        record "//table[@class='reportTable']" do
          name "/tr[2]/td[2]"
          registered_owner "/tr[7]//tr[1]/td[1]"
          phone "/tr[7]//tr[7]/td[1]"
          visit_address "/tr[8]/td[2]"
          mail_address "/tr[8]/td[3]"
          
          street_address "/tr[7]//tr[10]"
          postal_address "/tr[7]//tr[11]"
          postal_service_region "/tr[7]//tr[12]"
        end
      end
    end
    
    def parse_xml(company_record)
      doc = Nokogiri::HTML.parse(company_record.to_xml)
      
      company = {}
      company[:name] = doc.xpath('//root/record/name').text.strip rescue nil
      company[:registered_owner] = doc.xpath('//root/record/registered_owner').text.strip rescue nil
      company[:phone] = doc.xpath('//root/record/phone').text.strip rescue nil
      company[:visit_address] = doc.xpath('//root/record/visit_address').text.strip rescue nil
      company[:mail_address] = doc.xpath('//root/record/mail_address').text.strip rescue nil
      
      company[:street_address] = doc.xpath('//root/record/street_address').text.strip rescue nil
      company[:postal_address] = doc.xpath('//root/record/postal_address').text.strip rescue nil
      company[:postal_service_region] = doc.xpath('//root/record/postal_service_region').text.strip rescue nil
      company[:postal_code] = company[:postal_address].match(/[0-9]{3}[\s][0-9]{2}/)[0].strip rescue nil
      company[:postal_city] = company[:postal_address].match(/[a-zåäöA-ZÅÄÖ]+/)[0].strip rescue nil
      
      company[:registered_owner].gsub!(/[\w]+[:]/, '')
      registered_owner_array = company[:registered_owner].split(', ')
      company[:registered_owner_first_name] = registered_owner_array.last.strip rescue nil
      company[:registered_owner_last_name] = registered_owner_array.first.strip rescue nil
      company[:phone] = company[:phone].gsub!(/[\w]+[:]/, '').strip rescue nil
      
      company[:visit_address].gsub!(/(\s){36}/, '|')
      visit_address_array = company[:visit_address].split('|')
      visit_address_array = visit_address_array[1..-2] # remove BOTH first and last element
      company[:visit_street_address] = visit_address_array[0].strip rescue nil
      company[:visit_postal_code] = visit_address_array[1].match(/[0-9]{3}[\s][0-9]{2}/)[0].strip rescue nil
      company[:visit_postal_city] = visit_address_array[1].match(/[a-zåäöA-ZÅÄÖ]+/)[0].strip rescue nil
      company[:visit_postal_service_region] = visit_address_array[2].strip rescue nil
      
      company[:mail_address].gsub!(/(\s){36}/, '|')
      visit_address_array = company[:mail_address].split('|')
      visit_address_array = visit_address_array[1..-1] # remove ONLY first element
      company[:mail_street_address] = visit_address_array[0].strip rescue nil
      company[:mail_postal_code] = visit_address_array[1].match(/[0-9]{3}[\s][0-9]{2}/)[0].strip rescue nil
      company[:mail_postal_city] = visit_address_array[1].match(/[a-zåäöA-ZÅÄÖ]+/)[0].strip rescue nil
      company[:mail_postal_service_region] = visit_address_array[2].strip rescue nil
      
      company[:visit_street_address] ||= company[:street_address]
      company[:visit_postal_code] ||= company[:postal_code]
      company[:visit_postal_city] ||= company[:postal_city]
      company[:visit_postal_service_region] ||= company[:postal_service_region]
      
      company
    end
    
    def print_result(company)
      puts "\n=== COMPANY INFO ========================"
      puts "\nName:"
      puts "  #{company[:name] || '-'}"
      puts "\nPhone: "
      puts "  #{company[:phone] || '-'}"
      puts "\nRegistered Owner: "
      puts "  First Name: #{company[:registered_owner_first_name] || '-'}"
      puts "  Last Name: #{company[:registered_owner_last_name] || '-'}"
      puts "\nMail address: "
      puts "  Street: #{company[:mail_street_address] || '-'}"
      puts "  Postal Code: #{company[:mail_postal_code] || '-'}"
      puts "  City: #{company[:mail_postal_city] || '-'}"
      puts "  ServiceRegion: #{company[:mail_postal_service_region] || '-'}"
      puts "\nVisit address: "
      puts "  Street: #{company[:visit_street_address] || '-'}"
      puts "  Postal Code: #{company[:visit_postal_code] || '-'}"
      puts "  City: #{company[:visit_postal_city] || '-'}"
      puts "  ServiceRegion: #{company[:visit_postal_service_region] || '-'}"
      puts "\n========================================="
    end
  end
end