require 'json'

LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }


BjsOpsDashboard::App.controllers :ps_productivity_audit_m do
  
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
		listSupervisor = sequel.getSupervisors
		hashEngineer = sequel.getEngineers(listSupervisor, 'ps')
		sequel.close
		@listSupervisor = listSupervisor
		@hashEngineer = hashEngineer
		@jsonEngineer = hashEngineer.to_json
		render '/ps_productivity_audit_m/index', :layout => 'application'
	end

  post "/view_report" do
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
			r["Correspondences"] = sequel.getCorrespondenceCount(r["Login"], startDate, endDate)
			r["Chats"] = sequel.getChatCount(r["Login"], startDate, endDate)
			r["Total"] = r["Correspondences"] + r["Chats"]
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
		puts jsonReportData
		jsonReportData
  end

end
