require 'sequel'
require 'pp'
require 'json'
require 'date'

class DBConf

	def initialize
		@DB = Sequel.connect(:adapter => 'mysql2', :user => 'jiakeshu', :host => '127.0.0.1', :database => 'aws_support_cases_bjs',:password=>'12345678')
		#@DB.convert_invalid_date_time = nil
	end

	def close
		@DB.disconnect
	end

	def getEngineers(listSupervisor, role)
		hashEngineer = {} 
		hashRole = { "cs" => "TCSA%AWS", "ps" => "Cloud Support Engineer"}
		title = hashRole[role]
		listSupervisor.each { |supervisor|
			listEngineer = []
			sql = "select agent_login_id from agents_cn where supervisor_login_name='#{supervisor}' and title like '#{title}'"
			ds = @DB.fetch(sql)
			ds.each {|r| listEngineer << r[:agent_login_id]}
			hashEngineer[supervisor] = listEngineer
		}

		hashEngineer
	end

	def getSupervisors
		listSupervisor = []
		ds = @DB.fetch("select supervisor_login_name from supervisor")
		ds.each { |r| listSupervisor.push r[:supervisor_login_name] }
		listSupervisor
	end

	def getAgentInfo(login)
		result = {}
		hashRole = { "TCSA Â¿ AWS" => "TCSA", "Cloud Support Engineer" => "CSE"}
		ds = @DB.fetch("select agent_login_id, supervisor_login_name, title, amzn_hire_date from agents_cn where agent_login_id = '#{login}'")
		ds.each { |r| 
			result['Login'] = r[:agent_login_id]
			result['Manager'] = r[:supervisor_login_name]
			result['Title'] = hashRole[r[:title]]
			hire_date = DateTime.parse(r[:amzn_hire_date].to_time.strftime('%Y%m%d%H%M%S'))
			result['Tenure'] = (DateTime.now() - hire_date).to_i
		}

		result
	end

	def getAgentCorrespondenceCount(login, startDate, endDate)
		result = 0
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		#sql="select count(*) ct from o_communications_cn where owner_agent_login='#{login}' and date_add(CREATION_DATE, interval 8 hour)>='#{startDate}' and date_add(CREATION_DATE, interval 8 hour) < '#{endDate}' and COMM_TYPE_CODE='E'"
		sql="select count(o.comm_id) ct from o_communications_cn o, o_case_communications_cn c,d_case_details_cn d where c.comm_id = o.comm_id and c.case_id = d.case_id and owner_agent_login='#{login}' and d.primary_email_id not like 'aws%support%@amazon.com' and date_add(c.CREATION_DATE, interval 8 hour)>=str_to_date('#{startDate}','%Y%m%d') and date_add(c.CREATION_DATE, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') and COMM_TYPE_CODE='E' and o.IS_AMAZON_SENDER='Y'"
		ds = @DB.fetch(sql)
		ds.each { |r|
			result = r[:ct]
		}

		result
	end

	def getAgentCaseCountDS(login, startDate, endDate)
		result = 0
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		#sql = "select count(distinct(c.case_id)) ct from o_communications_cn o,o_case_communications_cn c where o.comm_id = c.comm_id and o.owner_agent_login='#{login}' and date_add(o.CREATION_DATE, interval 8 hour)>='#{startDate}' and date_add(o.CREATION_DATE, interval 8 hour) < '#{endDate}' and COMM_TYPE_CODE='E'"
		sql = "select count(distinct(c.case_id)) ct from o_communications_cn o,o_case_communications_cn c,d_case_details_cn d where o.comm_id = c.comm_id and d.case_id=c.case_id and o.owner_agent_login='#{login}' and d.primary_email_id not like 'aws%support%@amazon.com' and date_add(o.CREATION_DATE, interval 8 hour)>='#{startDate}' and date_add(o.CREATION_DATE, interval 8 hour) < '#{endDate}' and COMM_TYPE_CODE='E'"
		ds = @DB.fetch(sql)
		ds.each {|r|
			result = r[:ct]
		}

		result
	end

	def getChatCount(login, startDate, endDate)
		result = 0
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		#sql = "select count(distinct(case_id)) ct from o_case_communications_cn a, o_communications_cn b where b.owner_agent_login='#{login}' and date_add(b.creation_date, interval 8 hour)>='#{startDate}' and date_add(b.creation_date, interval 8 hour) < '#{endDate}' and a.comm_id = b.comm_id"
		sql = "select count(*) ct from o_communications_cn where owner_agent_login='#{login}' and date_add(CREATION_DATE, interval 8 hour)>='#{startDate}' and date_add(CREATION_DATE, interval 8 hour) < '#{endDate}' and COMM_TYPE_CODE='C'"
		ds = @DB.fetch(sql)
		ds.each { |r|
			result = r[:ct]
		}

		result
	end

	def getTTCount(login, startDate, endDate)
		result = 0
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		sql = "select count(*) ct from o_remedy_audittrail_cn where created_by='#{login}' and date_add(creat_date, interval 8 hour)>='#{startDate}' and date_add(creat_date, interval 8 hour)<'#{endDate}'"
		ds = @DB.fetch(sql)
		ds.each { |r|
			result = r[:ct]
		}

		result
	end
	
	def getWeeklyCRSPByQueue(type, startDate, endDate)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		sql = {};
		sql["PS"] = "select EMAIL_QUEUE_NAME queue_name, CONCAT(YEAR(date_add(m.CREATION_DATE, interval 8 hour)), '/', WEEK(date_add(m.CREATION_DATE, interval 8 hour),5)+1,'w')  week_name, count(m.comm_id) ct from d_case_details_cn c, o_case_communications_cn m,o_communications_cn t where c.case_id = m.case_id and m.comm_id=t.comm_id and date_add(m.CREATION_DATE, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(m.CREATION_DATE, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') and t.IS_AMAZON_SENDER='Y' and c.email_queue_name not like 'acme-aws-cs%' and c.primary_email_id not like ('aws%support%@amazon.com') group by week_name,c.EMAIL_QUEUE_NAME"
		sql["CS"] = "select EMAIL_QUEUE_NAME queue_name, CONCAT(YEAR(date_add(m.CREATION_DATE, interval 8 hour)), '/', WEEK(date_add(m.CREATION_DATE, interval 8 hour),5)+1,'w')  week_name, count(m.comm_id) ct from d_case_details_cn c, o_case_communications_cn m,o_communications_cn t where c.case_id = m.case_id and m.comm_id=t.comm_id and date_add(m.CREATION_DATE, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(m.CREATION_DATE, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') and t.IS_AMAZON_SENDER='Y' and c.email_queue_name like 'acme-aws-cs%' and c.primary_email_id not like 'aws%support%@amazon.com' group by week_name,c.EMAIL_QUEUE_NAME"
		ds = @DB.fetch(sql[type])

		ds
	end

	def getWeeklyCRSPByType(startDate, endDate)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		sql = "select CONCAT(YEAR(date_add(m.CREATION_DATE, interval 8 hour)), '/', WEEK(date_add(m.CREATION_DATE, interval 8 hour),5)+1,'w')  week_name,t.type, count(m.comm_id) ct from d_case_details_cn c, o_case_communications_cn m, o_communications_cn comm, t_acme_case_queue_type t where c.case_id = m.case_id and m.comm_id = comm.comm_id and comm.is_amazon_sender='Y' and date_add(m.CREATION_DATE, interval 9 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(m.CREATION_DATE, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') and c.primary_email_id not like ('aws%support%@amazon.com') and c.email_queue_name = t.acme_case_queue_name group by type,week_name;"		
		ds = @DB.fetch(sql)

		ds
	end

	def getWeeklyCasesByStatus(team, startDate, endDate)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
    sql = "select CONCAT(YEAR(date_add(CASE_START_DATE_UTC, interval 8 hour)), '/', WEEK(date_add(CASE_START_DATE_UTC, interval 8 hour),5)+1,'w')  week_name, CASE_STATUS_NAME status, count(c.case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by week_name,status"
		ds = @DB.fetch(sql)

		ds
	end

	def getWeeklyCasesBySeverity(team, startDate, endDate)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
    sql = "select CONCAT(YEAR(date_add(CASE_START_DATE_UTC, interval 8 hour)), '/', WEEK(date_add(CASE_START_DATE_UTC, interval 8 hour),5)+1,'w')  week_name, severity, count(c.case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by week_name,severity"
		ds = @DB.fetch(sql)
		ds
	end

	def getCreatedCaseCount(team, startDate, endDate, granu)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		granuText = getGranuText(granu, "CASE_START_DATE_UTC")
		sql = "select #{granuText} period, count(c.case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by period"
		ds = @DB.fetch(sql)

		ds
	end

	def getClosedCaseCount(team, startDate, endDate, granu)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		granuText = getGranuText(granu, "CASE_RESOLVE_DATE_UTC")
		sql = "select #{granuText} period, count(c.case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and date_add(CASE_RESOLVE_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_RESOLVE_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by period"
		ds = @DB.fetch(sql)

		ds
	end

	def getCorrespondenceCount(team, startDate, endDate, granu)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		granuText = getGranuText(granu, "o.CREATION_DATE")
		titleMapping = {"PS" => "Cloud Support Engineer", "CS" => "TCSA%"}
		title = titleMapping[team]
		#sql = "select #{granuText} period,count(*) ct from o_communications_cn where owner_agent_login in (select agent_login_id from agents_cn where title like '#{title}') and date_add(CREATION_DATE, interval 8 hour)>=str_to_date('#{startDate}','%Y%m%d') and date_add(CREATION_DATE, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') and COMM_TYPE_CODE='E' group by period"
		sql = "select #{granuText} period,count(o.comm_id) ct from o_communications_cn o,o_case_communications_cn c,d_case_details_cn d where d.case_id=c.case_id and c.comm_id = o.comm_id and owner_agent_login in (select agent_login_id from agents_cn where title like '#{title}') and d.primary_email_id not like 'aws%support%@amazon.com' and date_add(o.CREATION_DATE, interval 8 hour)>=str_to_date('#{startDate}','%Y%m%d') and date_add(o.CREATION_DATE, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') and COMM_TYPE_CODE='E' group by period"
		ds = @DB.fetch(sql)
		ds
	end

	def getOpeningCasesDS(team)
		sql = "select case_status_name,count(case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and case_status_name <> 'Resolved' group by case_status_name;"
		ds = @DB.fetch(sql)
		ds
	end

	def getOpeningCasesDrilldownDS(team)
		sql = "select case_status_name,email_queue_name,count(case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and case_status_name <> 'Resolved' group by case_status_name, email_queue_name;"
		ds = @DB.fetch(sql)
		ds
	end

	def getCaseDurationDS(team, startDate, endDate, granu)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		granuText = getGranuText(granu, "CASE_START_DATE_UTC")
		titleMapping = {"PS" => "Cloud Support Engineer", "CS" => "TCSA%"}
		title = titleMapping[team]
		sql = "select CASE when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) >=0 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=24 then 'less than 1 day' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) > 24 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=48 then '1 ~ 2 days' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) > 48 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=96  then '2 ~ 4 days' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) is null then 'opening' else 'more than 4 days' END duration, #{granuText} period, count(c.case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by duration, period;"
		ds = @DB.fetch(sql)

		ds
	end

	def getTTRSeverityDS(team, startDate, endDate, granu)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		granuText = getGranuText(granu, "CASE_START_DATE_UTC")
		titleMapping = {"PS" => "Cloud Support Engineer", "CS" => "TCSA%"}
		title = titleMapping[team]
		sql = "select CASE when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) >=0 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=24 then 'less than 1 day' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) > 24 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=48 then '1 ~ 2 days' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) > 48 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=96  then '2 ~ 4 days' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) is null then 'opening' else 'more than 4 days' END duration,severity, #{granuText} period, count(c.case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by duration,severity, period;"
		ds = @DB.fetch(sql)

		ds
	end

	def getCaseSLAStatisticsDS(team, startDate, endDate, granu)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		granuText = getGranuText(granu, "CASE_START_DATE_UTC")
		titleMapping = {"PS" => "Cloud Support Engineer", "CS" => "TCSA%"}
		title = titleMapping[team]
		#sql = "select CASE when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) >=0 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=24 then 'less than 1 day' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) > 24 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=48 then '1 ~ 2 days' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) > 48 and timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) <=96  then '2 ~ 4 days' when timestampdiff(hour,case_start_date_utc,case_resolve_date_utc) is null then 'opening' else 'more than 4 days' END duration, #{granuText} period, count(c.case_id) ct from d_case_details_cn c, t_acme_case_queue_type t where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and c.primary_email_id not like 'aws%support%@amazon.com' and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by duration, period;"
		sql = "select (CASE when timestampdiff(minute, case_start_date_utc, FIRST_OUTBOUND_DATE_UTC) - sla <=0 THEN 'meet' ELSE 'fail' END) case_sla, #{granuText} period, count(case_id) ct from d_case_details_cn c, t_acme_case_queue_type t, t_case_sla s where c.email_queue_name=t.acme_case_queue_name and t.team='#{team}' and s.severity = c.severity and c.primary_email_id not like 'aws%support%@amazon.com' and primary_email_id not like 'feliwang%@amazon.com' and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') group by case_sla,period;"
		puts sql
		ds = @DB.fetch(sql)

		ds
	end

	def getCaseReviewListDS(agents, startDate, endDate, team)
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s 
		for i in 0..agents.length - 1
			agents[i] = "\'" + agents[i] + "\'"
		end
		strAgents = agents.join(",")

		#sql = "select CASE_ID, CASE_DESCRIPTION, MERCHANT_CUSTOMER_ID partner_id, ALT_MERCHANT_NAME customer, CASE_STATUS_NAME,date_add(CREATION_DATE_UTC,interval 8 hour) start_date, date_add(CASE_RESOLVE_DATE_UTC,interval 8 hour) resolve_date, FIRST_HANDLING_AGENT_ID, OWNING_AGENT_LOGIN_ID, CATEGORY_NAME, CASE_TYPE_NAME from d_case_details_cn where (OWNING_AGENT_LOGIN_ID in (#{strAgents}) or (EMAIL_QUEUE_NAME in (select acme_case_queue_name from t_acme_case_queue_type where team='#{team}') and OWNING_AGENT_LOGIN_ID is null)) and primary_email_id not like 'aws%@amazon.com' and primary_email_id not like 'authmaster-bjs%@amazon.com' and primary_email_id not in ('aws-cn-dawnraid@amazon.com','cornelle+bjs@amazon.com','feliwang+1@amazon.com','nobody@amazon','karen.doughty@gmail.com','feliwang+1@amazon.com') order by case_id desc;"
		sql = "select c.CASE_ID,c.SEVERITY, c.CASE_DESCRIPTION, c.ALT_MERCHANT_NAME customer, c.CASE_STATUS_NAME, date_format(date_add(CREATION_DATE_UTC,interval 8 hour),'%Y-%m-%d %H:%i:%s') start_date, date_format(date_add(CASE_RESOLVE_DATE_UTC,interval 8 hour),'%Y-%m-%d %H:%i:%s') resolve_date, date_format(review_date,'%Y-%m-%d %H:%i:%s') review_date, FIRST_HANDLING_AGENT_ID, c.OWNING_AGENT_LOGIN_ID, reviewer_login_id from d_case_details_cn c left join d_case_reviews r on c.case_id = r.case_id  where (c.OWNING_AGENT_LOGIN_ID in (#{strAgents}) or (EMAIL_QUEUE_NAME in (select acme_case_queue_name from t_acme_case_queue_type where team='#{team}') and c.OWNING_AGENT_LOGIN_ID is null)) and primary_email_id not like 'aws%@amazon.com' and primary_email_id not like 'authmaster-bjs%@amazon.com' and primary_email_id not in ('aws-cn-dawnraid@amazon.com','cornelle+bjs@amazon.com','feliwang+1@amazon.com','nobody@amazon','karen.doughty@gmail.com','feliwang+1@amazon.com') and date_add(CASE_START_DATE_UTC, interval 8 hour) >= str_to_date('#{startDate}','%Y%m%d') and date_add(CASE_START_DATE_UTC, interval 8 hour) < str_to_date('#{endDate}','%Y%m%d') order by case_id desc;"
		puts sql
		ds = @DB.fetch(sql)

		ds
	end

	def getCaseReviewDetailDS(caseID)
		sql = "select r.*,c.case_status_name from d_case_reviews r, d_case_details_cn c where c.case_id=r.case_id and r.case_id=#{caseID}"
		pp sql
		ds = @DB.fetch(sql)

		ds
		
	end

	def getCaseReviewReportDS(team)
		sql = "select case_id, severity, ir_template,annotation,handover_template,timely_update, closure_template,closure_template, courtesy, wording, technical_expertise,comments,owning_agent_login_id,reviewer_login_id,closure_consent from d_case_reviews where team='#{team}';"

		ds = @DB.fetch(sql)
	end
	
	def getCaseDetailDS(caseID)
		sql = "select case_id,c.severity,OWNING_AGENT_LOGIN_ID,timestampdiff(day,case_start_date_utc,case_resolve_date_utc) ttr,ALT_MERCHANT_NAME,CASE_DESCRIPTION,(CASE when timestampdiff(minute, case_start_date_utc, FIRST_OUTBOUND_DATE_UTC) - sla <=0 THEN 'meet' ELSE 'fail' END) SLA,CASE_STATUS_NAME from d_case_details_cn c,t_case_sla s where s.severity = c.severity and c.case_id=#{caseID};"
		pp sql
		ds = @DB.fetch(sql)

		ds
	end

	def submitReview(params)
		column_map = {"case_id"=>"case_id","severity"=>"severity","ALT_MERCHANT_NAME"=>"customer","case_description"=>"subject","OWNING_AGENT_LOGIN_ID"=>"owner","SLA"=>"sla","TTR"=>"ttr","ir_template"=>"ir_template","timely_update"=>"timely_update","handover_template"=>"handover_template","closure_template"=>"closure_template","comments"=>"comments","courtesy"=>"courtesy","wording"=>"wording","technical_expertise"=>"technical_expertise","reviewer_login_id"=>"reviewer","annotation"=>"annotation","closure_consent"=>"closure_consent","team"=>"team"}
		if params["insert_flag"] == "1"
			column_list = []
			placeholder_list = []
			value_list = []
			column_map.each do |k,v|
				puts k,v
				column_list << k
				value_list << "'"+params[v].gsub(/'/,"''")+"'"
			end
			column_list << "review_date"
			value_list << "now()"
			sql = "insert into d_case_reviews (#{column_list.join(",")}) values (#{value_list.join(",")})"
			puts sql
			insert_ds = @DB[sql]
			insert_ds.insert
		elsif params["insert_flag"] == "0"
				listUpdate = []
			column_map.each do |k,v|
				listUpdate << k + "=" + "'"+params[v].gsub(/'/,"''")+"'"
			end
			listUpdate << "review_date=now()"
			sql = "update d_case_reviews set #{listUpdate.join(",")} where case_id=#{params["case_id"]}"
			puts sql
			update_ds = @DB[sql]
			update_ds.update
		end
	end

	def getGranuText(granu , columnName)
		arrayGranu = { "week" => "CONCAT(YEAR(date_add(#{columnName}, interval 8 hour)), '/', WEEK(date_add(#{columnName}, interval 8 hour),5)+1,'w')", "month" => "YEAR(date_add(#{columnName}, interval 8 hour))"}

		arrayGranu[granu]	
	end

end
