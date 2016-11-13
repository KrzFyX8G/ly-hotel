require "spec_helper"

describe Ly::Hotel do
  it "has a version number" do
    expect(Ly::Hotel::VERSION).not_to be nil
  end

  it "number of provinces" do
    api = Ly::Hotel::Api.new(ENV["LY_HOTEL_API_ACCOUNT_ID"], ENV["LY_HOTEL_API_PASSWORD"], ENV["LY_HOTEL_API_HOST"])
    begin
      result = api.request('general/AdministrativeDivisions', 'GetProvinceList')
    rescue Ly::Hotel::Error => e
      puts e.code
      puts e.message
    end
    unless result.nil?
      result["provinceList"]["province"].each do |province|
        puts "#{province["id"]}\t#{province["name"]}"
      end
      expect(result["provinceList"]["totalCount"].to_i).to eq(34)
    end
  end
  
  it "number of cities" do
    api = Ly::Hotel::Api.new(ENV["LY_HOTEL_API_ACCOUNT_ID"], ENV["LY_HOTEL_API_PASSWORD"], ENV["LY_HOTEL_API_HOST"])
    result = api.request('general/AdministrativeDivisions', 'GetCityListByProvinceId', provinceId: 25)
    puts api.req_xml
    puts api.resp_xml
    result["cityList"]["city"] = [result["cityList"]["city"]] unless result["cityList"]["city"].is_a?(Array)
    result["cityList"]["city"].each do |city|
      puts "#{city["id"]}\t#{city["name"]}"
    end
    expect(result["cityList"]["totalCount"].to_i).to eq(1)
  end
end
