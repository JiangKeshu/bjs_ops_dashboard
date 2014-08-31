require 'json'

LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }


BjsOpsDashboard::App.controllers :productivity_audit_m do
  
  # get :index, :map => '/foo/bar' do
  #   session[:foo] = 'bar'
  #   render 'index'
  # end

  # get :sample, :map => '/sample/url', :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   'Maps to url '/foo/#{params[:id]}''
  # end

  # get '/example' do
  #   'Hello world!'
	# end
	get :index do
		sequel = DBConf.new
		team = params[:team].nil?? 'ps' : params[:team]
		listSupervisor = sequel.getSupervisors
		hashEngineer = sequel.getEngineers(listSupervisor, team)
		sequel.close
		@listSupervisor = listSupervisor
		@hashEngineer = hashEngineer
		@jsonEngineer = hashEngineer.to_json
		render '/productivity_audit_m/index', :layout => 'application'
	end

  post "/view_report" do
		team = params[:team]
		agents = params[:users]
		startDate =  params[:start_date]
		endDate = params[:end_date]
		sequel = DBConf.new
		arrayAgents = []
		agents.each { |agent|
			agentInfo = sequel.getAgentInfo(agent)
			arrayAgents << agentInfo
		}
		arrayReportData = []
		arrayAgents.each { |r|
			t = {}
			user_login = r["Login"]
			tt_statistic =sequel.getTTCount(user_login, startDate, endDate)
			user_url = "<a href='agent_report?agent=#{user_login}'>#{user_login}</a>"
			t["login"] = user_url
			t["cases"] = sequel.getAgentCaseCountDS(user_login, startDate, endDate)
			t["correspondences"] = sequel.getAgentCorrespondenceCount(user_login, startDate, endDate)
			t["chats"] = sequel.getChatCount(user_login, startDate, endDate)
			t["tt_correspondences"] = tt_statistic["tt_crsp"]
			t["total"] = t["correspondences"] + t["chats"] + t["tt_correspondences"]
			t["threshold"] = 128
			t["manager"] = r["Manager"]
			t["title"] = r["Title"]
			t["tenure"] = r["Tenure"]			
			t["tt_count"] = tt_statistic["tt_count"]
			arrayReportData << t
			}
		hashReportData = {}
		hashReportData["data"] = arrayReportData
		sequel.close
		#puts jsonReportData
		hashReportData.to_json
  end


end
