#encoding:utf-8
require "iconv"

require 'json'
require 'date'
require 'pp'
LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }

class RawdataUtil

	attr_accessor :datatable_json_map

	def initialize 
		@datatable_json_map = {
			'week_cases_by_status' => { 'datatable' => [{'title'=>'Period','data'=>'period'},{'title'=>'Status','data'=>'status'},{'title'=>'Case ID','data'=>'case_id'}], 'header' => 'Cases by status'},
			'opening_cases' => { 'datatable' => [{'title'=>'Period','data'=>'period'},{'title'=>'Status','data'=>'status'},{'title'=>'Case ID','data'=>'case_id'}], 'header' => 'Opening cases'},
			'case_sla_chart' => { 'datatable' => [{'title'=>'Period','data'=>'period'},{'title'=>'Case ID','data'=>'case_id'},{'title'=>'SLA','data'=>'case_sla'}], 'header' => 'Case SLA'}
     
		}
	end
		
	def get_datatable_structure(view)
		@datatable_json_map[view]
	end
	
	def get_rawdata(params)
		sequel = DBConf.new
		ds = sequel.get_rawdata_ds(params)
		records = []
		ds.each do |r|
			hash_record = {}
			@datatable_json_map[params[:view]]['datatable'].each do |l|
				if l['data'] != 'case_id' 
					hash_record[l['data']] = r[l['data'].to_sym]
				else
					case_id = r[l['data'].to_sym]
					hash_record[l['data']] = "<a href='https://cscentral-cn.amazon.com/gp/stores/www.amazon.cn/gp/acme/case-management/view-case/?caseID=#{case_id}' target='_Blank'><img src='/images/yuma.png'></img>&nbsp;#{case_id}</a>"
				end 
			end
			records << hash_record	
		end
		sequel.close()
		result = { "data" => records }
		result.to_json.html_safe
	end

end
