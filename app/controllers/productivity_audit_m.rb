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
			user_login = r["Login"]
			user_url = "<a href='agent_report?agent=#{user_login}'>#{user_login}</a>"
			r["Login"] = user_url
			r["Cases"] = sequel.getAgentCaseCountDS(user_login, startDate, endDate)
			r["Correspondences"] = sequel.getAgentCorrespondenceCount(user_login, startDate, endDate)
			r["Chats"] = sequel.getChatCount(user_login, startDate, endDate)
			r["TTs"] = sequel.getTTCount(user_login, startDate, endDate)
			r["Total"] = r["Correspondences"] + r["Chats"] + r["TTs"]
			r["Threshold"] = 128
			#r["ttCount"] = sequel.getTTCount(r["agent"], startDate, endDate)
			arrayTmp = []
			r.each { |k,v|
				arrayTmp << v
			}
			arrayReportData << arrayTmp
		}
		jsonReportData = arrayReportData.to_json
		sequel.close
		#puts jsonReportData
		jsonReportData
  end


end
