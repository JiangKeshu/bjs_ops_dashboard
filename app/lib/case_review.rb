#encoding:utf-8
require "iconv"

require 'json'
require 'date'
require 'pp'
LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }

def getCaseReviewList(agents, startDate, endDate, team, ms_case_status)

	result = []
	sequel = DBConf.new
	ds = sequel.getCaseReviewListDS(agents, startDate, endDate, team, ms_case_status)

	ds.each do |r|
		t = []	
		r.each do |k,v|
			if v.class.to_s == "BigDecimal"
					value = v.to_i
			else 
				value = v
			end
			if k.to_s == "CASE_ID"
				value = "<a href='/case_review/review/?caseID=#{value}&team=#{team}' target='_Blank'>#{value}</a>&nbsp;&nbsp;<a href='https://cscentral-cn.amazon.com/gp/stores/www.amazon.cn/gp/acme/case-management/view-case/?caseID=#{value}' target='_Blank'><img src='/images/yuma.png'></img></a>"
			end
			t << value
		end
		result << t
	end

	sequel.close()
	result.to_json
end

def getCaseReviewReport(startDate, endDate, team)
	data = []
	result = {}
	sequel = DBConf.new
	ds = sequel.getCaseReviewReportDS(team)
	hashOptionsMap={'ir_template'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'Yes','score'=>1},'2'=>{'option'=>'No','score'=>0}},'annotation'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'Good','score'=>1},'2'=>{'option'=>'Development needed','score'=>0}},'handover_template'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'Yes','score'=>1},'2'=>{'option'=>'No','score'=>0}},'timely_update'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'All the time','score'=>1},'2'=>{'option'=>'Most of time','score'=>0},'3'=>{'option'=>'Sometimes','score'=>0},'4'=>{'option'=>'Rare','score'=>0}},'closure_template'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'Yes','score'=>1},'2'=>{'option'=>'No','score'=>0}},'closure_consent'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'Yes','score'=>1},'2'=>{'option'=>'No','score'=>0}},'courtesy'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'Good','score'=>1},'2'=>{'option'=>'Development needed','score'=>0}},'wording'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'Good','score'=>1},'2'=>{'option'=>'Development needed','score'=>0}},'technical_expertise'=>{'0'=>{'option'=>'N/A','score'=>1},'1'=>{'option'=>'No gap observed','score'=>1},'2'=>{'option'=>'Gap observed','score'=>0},'3'=>{'option'=>'Immediate coach needed','score'=>0}}}
	hashScoreItems=['ir_template','annotation','handover_template','timely_update','closure_template','closure_consent','courtesy','wording','technical_expertise']
	ds.each do |r|
		t = {}
		score = 0
		t["case_id"] = "<a href='/case_review/review/?caseID=#{r[:case_id]}&team=#{team}' target='_Blank'>#{r[:case_id]}</a>&nbsp;&nbsp;<a href='https://cscentral-cn.amazon.com/gp/stores/www.amazon.cn/gp/acme/case-management/view-case/?caseID=#{r[:case_id]}' target='_Blank'><img src='/images/yuma.png'></img></a>"
		t["severity"] = r[:severity]
		t["review_date"] = r[:review_date]
		hashScoreItems.each do |item|
			if !r[item.to_sym].nil?
				t[item] = hashOptionsMap[item][r[item.to_sym].to_s]['option']
				score = score + hashOptionsMap[item][r[item.to_sym].to_s]['score']
			else
				t[item] = 'Null'
				score = score + 0
			end
		end
		t["comments"] = r[:comments].gsub(/\n/,'<br/>')
		t["reviewer"] = r[:reviewer_login_id]
		t["score"] = score
		t["highlight_flag"] = r[:highlight_flag]
		data << t	
	end
		
	result["data"] = data	
	sequel.close()
	puts result.to_json
	result.to_json
end

def getCaseReviewDetail(caseID)
	#Get review detail
	caseReviewDetail = {}
	sequel = DBConf.new
	ds = sequel.getCaseReviewDetailDS(caseID)
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
			caseReviewDetail["annotation"] = r[:annotation]
			#caseReviewDetail["adm_in_place"] = r[:adm_in_place]
			caseReviewDetail["handover_template"] = r[:handover_template]
			caseReviewDetail["closure_template"] = r[:closure_template]
			caseReviewDetail["closure_consent"] = r[:closure_consent]
			caseReviewDetail["courtesy"] = r[:courtesy]
			caseReviewDetail["wording"] = r[:wording]
			caseReviewDetail["technical_expertise"] = r[:technical_expertise]
			caseReviewDetail["reviewer"] = r[:reviewer_login_id]
			caseReviewDetail["comments"] = r[:comments]
			caseReviewDetail["highlight_flag"] = r[:highlight_flag]
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
			caseReviewDetail["annotation"] = 0
			#caseReviewDetail["adm_in_place"] = 0
			caseReviewDetail["handover_template"] = 0
			caseReviewDetail["closure_template"] = 0
			caseReviewDetail["closure_consent"] = 0
			caseReviewDetail["courtesy"] = 0
			caseReviewDetail["wording"] = 0
			caseReviewDetail["reviewer"] = ''
			caseReviewDetail["technical_expertise"] = 0
			caseReviewDetail["comments"] = ""
			caseReviewDetail["highlight_flag"] = "false"
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
		puts $!.inspect, $@
		statusWord = "Submit failed"
	ensure
		sequel.close()
	end

	statusWord
end
