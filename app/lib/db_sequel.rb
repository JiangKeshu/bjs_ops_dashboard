require 'sequel'
require 'pp'
require 'json'
require 'date'

class DBConf

	def initialize
		@DB = Sequel.connect('mysql://jiakeshu:12345678@127.0.0.1:3306/aws_support_cases_bjs')
		@DB.convert_invalid_date_time = nil
	end

	def close
		@DB.disconnect
	end

	def getEngineers(listSupervisor, role)
		hashEngineer = {} 
		hashRole = { "cs" => "TCSA Â¿ AWS", "ps" => "Cloud Support Engineer"}
		title = hashRole[role]
		listSupervisor.each { |supervisor|
			listEngineer = []
			ds = @DB.fetch("select agent_login_id from agents_cn where supervisor_login_name='#{supervisor}' and title='#{title}'")
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
			#puts DateTime.parse(result['hire_date'])
		}

		result
	end

	def getCorrespondenceCount(login, startDate, endDate)
		result = 0
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		ds = @DB.fetch("select count(*) ct from o_communications_cn where owner_agent_login='#{login}' and date_add(CREATION_DATE, interval 8 hour)>='#{startDate}' and date_add(CREATION_DATE, interval 8 hour) < '#{endDate}'")
		ds.each { |r|
			result = r[:ct]
		}

		result
	end

	def getChatCount(login, startDate, endDate)
		result = 0
		endDate = (DateTime.parse(endDate, "%Y%m%d") + 1).strftime("%Y%m%d").to_s
		sql = "select count(distinct(case_id)) ct from o_case_communications_cn a, o_communications_cn b where b.owner_agent_login='#{login}' and date_add(b.creation_date, interval 8 hour)>='#{startDate}' and date_add(b.creation_date, interval 8 hour) < '#{endDate}' and a.comm_id = b.comm_id"
		ds = @DB.fetch(sql)
		ds.each { |r|
			result = r[:ct]
		}

		result
	end

	def getTTCount(login, startDate, endDate)
	end

end
