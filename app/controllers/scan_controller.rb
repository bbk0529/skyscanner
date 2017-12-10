require 'rest-client'
require 'json'
require 'nokogiri'
require 'time'
require 'active_support'
require 'active_support/core_ext'
require 'csv'
require 'awesome_print'

class ScanController < ApplicationController

  def index
    p "haha"
    @airport=[]
    CSV.foreach('airport.csv') do |row|
        @airport << row
        p row
    end

  end

  def search
    p "kakakaka"

    @departure = params[:departure]
    @arrival = params[:arrival]
    @s_month= params[:s_month]
    @e_month= params[:e_month]

    period_start = params[:period_start].to_i
    period_finish = params[:period_finish].to_i
    budget = params[:budget].to_i
    search_start=1
    search_end=30

    headers = {
        "user-agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36"
    }
    url = "https://www.skyscanner.co.kr/dataservices/browse/v3/mvweb/KR/KRW/ko-KR/calendar/#{@departure}/#{@arrival}/#{@s_month}/#{@e_month}/?profile=minimalmonthviewgrid&abvariant=GDT1606_ShelfShuffleOrSort:b|GDT1606_ShelfShuffleOrSort_V5:b|RTS2189_BrowseTrafficShift:b|RTS2189_BrowseTrafficShift_V8:b|rts_mbmd_anylegs:b|rts_mbmd_anylegs_V5:b|GDT1693_MonthViewSpringClean:b|GDT1693_MonthViewSpringClean_V13:b|GDT2195_RolloutMicroserviceIntegration:b|GDT2195_RolloutMicroserviceIntegration_V4:b"
    p url
    result=JSON.parse(RestClient.get(url, headers))
    p result
    go(@departure,@arrival,search_start, search_end, period_start, period_finish, budget, result)
  end

  def go(dk,k,search_start, search_end, period_start, period_finish, limit, result)
  	array1=[]
  	array2=[]
  	min1=[]
  	min2=[]
      (period_start..period_finish).to_a.each do |period|
          (search_start..search_end).to_a.each do |j|
              break if (j+period) >= search_end
              outbound = result['PriceGrids']['Grid'][0][j-1]['DirectOutboundPrice']
              inbound = result['PriceGrids']['Grid'][j-1+period][j-1]['DirectInboundPrice']

              outbound2 = result['PriceGrids']['Grid'][0][j-1]['IndirectOutboundPrice']
              inbound2 = result['PriceGrids']['Grid'][j-1+period][j-1]['IndirectInboundPrice']

              p "            " +"direct" + j.to_s + "일 부터 " + (j+period).to_s + "일 까지 " + period.to_s + "일 동안 " + (outbound + inbound).to_s + "원입니다" if  outbound && inbound && ((inbound + outbound) < limit)
              p "            " +"Indirect" + j.to_s + "일 부터 " + (j+period).to_s + "일 까지 " + period.to_s + "일 동안 " + (outbound2 + inbound2).to_s + "원입니다" if  outbound2 && inbound2 && ((inbound2 + outbound2) < limit)

  				if  outbound && inbound && ((inbound + outbound) < limit)
  					array1.push([dk,k,"direct",j,j+period, period, (outbound+inbound)])
  					min1.push(outbound+inbound)
  				end

  				if  outbound2 && inbound2 && ((inbound2 + outbound2) < limit)
  					array2.push([dk,k,"indirect",j,j+period, period, (outbound2+inbound2)])
  					min2.push(outbound2+inbound2)
  				end

  			end

      end
      @direct_all = array1
      @indirect_all = array2
      @direct=array1[min1.index(min1.min)] if min1.size!=0
      @indirect=array2[min2.index(min2.min)] if min2.size!=0
    end
end
