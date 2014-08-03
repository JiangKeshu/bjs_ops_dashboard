#encoding:utf-8
require "iconv"

require 'json'
require 'date'
require 'pp'
LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }

def getCaseReviewList(agents, startDate, endDate, team)

	result = []
	sequel = DBConf.new
	ds =sequel.getCaseReviewListDS(agents, startDate, endDate, team)

	ds.each do |r|
		t = []	
		r.each do |k,v|
			if v.class.to_s == "BigDecimal"
					value = v.to_i
			else 
				value = v
			end
			if k.to_s == "CASE_ID"
				value = "<a href='/case_review/review/?caseID=#{value}' target='_Blank'>#{value}</a>&nbsp;&nbsp;<a href='https://cscentral-cn.amazon.com/gp/stores/www.amazon.cn/gp/acme/case-management/view-case/?caseID=#{value}' target='_Blank'><img src='/images/yuma.png'></img></a>"
			end
			t << value
		end
		result << t
	end
	result.to_json
end

def getCaseReviewDetail(caseID)
	#Get review detail
	caseReviewDetail = {}
	sequel = DBConf.new
	ds = sequel.getCaseReviewDetailDS(caseID)
	puts ds.count
	if ds.count != 0
		ds.each do |r|
			caseReviewDetail["caseID"] = r[:case_id]
			caseReviewDetail["Severity"] = r[:severity]
			caseReviewDetail["Customer"] = r[:ALT_MERCHANT_NAME]
			caseReviewDetail["Description"] = r[:case_description]
			caseReviewDetail["Owner"] = r[:OWNING_AGENT_LOGIN_ID]
			caseReviewDetail["SLA"] = r[:SLA]
			caseReviewDetail["TTR"] = r[:TTR]
			caseReviewDetail["Status"] = r[:case_status_name]
			caseReviewDetail["ir_template"] = r[:ir_template]
			caseReviewDetail["timely_update"] = r[:timely_update]
			#caseReviewDetail["adm_in_place"] = r[:adm_in_place]
			caseReviewDetail["handover_template"] = r[:handover_template]
			caseReviewDetail["closure_template"] = r[:closure_template]
			caseReviewDetail["courtesy"] = r[:courtesy]
			caseReviewDetail["wording"] = r[:wording]
			caseReviewDetail["technical_expertise"] = r[:technical_expertise]
			caseReviewDetail["reviewer"] = r[:reviewer_login_id]
			caseReviewDetail["comments"] = r[:comments]
			caseReviewDetail["insert_flag"] = 0
		end
	else
		ds = sequel.getCaseDetailDS(caseID)
		ds.each do |r|
			caseReviewDetail["caseID"] = r[:case_id]
			caseReviewDetail["Severity"] = r[:severity]
			caseReviewDetail["Customer"] = r[:ALT_MERCHANT_NAME]
			caseReviewDetail["Description"] = r[:CASE_DESCRIPTION]
			caseReviewDetail["Owner"] = r[:OWNING_AGENT_LOGIN_ID]
			caseReviewDetail["SLA"] = r[:SLA]
			caseReviewDetail["TTR"] = r[:ttr]
			caseReviewDetail["Status"] = r[:CASE_STATUS_NAME]
			caseReviewDetail["ir_template"] = 0
			caseReviewDetail["timely_update"] = 0
			#caseReviewDetail["adm_in_place"] = 0
			caseReviewDetail["handover_template"] = 0
			caseReviewDetail["closure_template"] = 0
			caseReviewDetail["courtesy"] = 0
			caseReviewDetail["wording"] = 0
			caseReviewDetail["reviewer"] = ''
			caseReviewDetail["technical_expertise"] = 0
			caseReviewDetail["comments"] = ""
			caseReviewDetail["insert_flag"] = 1
		end
	end

	sequel.close()
	
	caseReviewDetail
end

def submitReview(params)
	begin 
		insert_flag = params[:insert_flag]
		sequel = DBConf.new
		ds = sequel.submitReview(params)
		statusWord = "Submit success"
	rescue
		statusWord = "Submit failed"
	ensure
		sequel.close()
	end

	statusWord
end
