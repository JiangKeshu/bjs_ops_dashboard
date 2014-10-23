require 'json'
require 'date'
LIB_PATH = File.dirname(__FILE__) + '/../lib/'
TEMPLATE_PATH = File.dirname(__FILE__) + '/../template/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }

BjsOpsDashboard::App.controllers :war_room_reports do
  
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

  get :volume do
		sequel = DBConf.new
    listSupervisor = sequel.getSupervisors
    hashEngineer = sequel.getEngineers(listSupervisor, 'ps')
    sequel.close
    @listSupervisor = listSupervisor
    @hashEngineer = hashEngineer
    @jsonEngineer = hashEngineer.to_json
		@str_pie_chart = '//abc'
		render '/war_room_reports/volume', :layout => 'application'
	end

	post "/gen_wrr_volume" do
		data = {}
		startDate = params[:start_date]
		endDate = params[:end_date]
		data["weeklyCRSPByQueuePS"] = getWeeklyCRSPByQueue('PS', startDate, endDate)
		data["weeklyCRSPByQueueCS"] = getWeeklyCRSPByQueue('CS', startDate, endDate)
		data["weeklyCRSPByType"] = getWeeklyCRSPByType(startDate, endDate)
		data["weeklyCasesByStatusPS"] = getWeeklyCasesByStatus('PS', startDate, endDate)
		data["weeklyCasesByStatusCS"] = getWeeklyCasesByStatus('CS', startDate, endDate)
		data["weeklyCasesBySeverityPS"] = getWeeklyCasesBySeverity('PS', startDate, endDate)
		data["weeklyCasesBySeverityCS"] = getWeeklyCasesBySeverity('CS', startDate, endDate)
		
		data.to_json
	end

	post "/gen_workload_report" do
		data = {}
		startDate = params[:start_date]
		endDate = params[:end_date]
		team = params[:team]
		data = getWorkloadReport(team, startDate, endDate, "week")
		data.to_json
	end

	post "/gen_opening_cases" do
		team = params[:team]
		chartContainer = params[:container]
		assigns = getOpeningCases(team, chartContainer)
		template = File.new(TEMPLATE_PATH + "pie_chart.erb").read
		strJS = template.eruby(assigns)
		return strJS
	end
	
	post "/gen_case_crsp_chart" do
		startDate = params[:start_date]
		endDate = params[:end_date]
		team = params[:team]
		container = params[:container]
		assigns = getCaseCRSPChart(team, startDate, endDate, container)
		template = File.new(TEMPLATE_PATH + "column_spline.erb").read
		
		#strJS = template.eruby(assigns)
		strJS = ''
		strJS
	end

	post "/get_case_duration" do
		startDate = params[:start_date]
		endDate = params[:end_date]
		team = params[:team]
		container = params[:container]
		assigns = getCaseDurationChart(team, startDate, endDate, container, "week")
		template = File.new(TEMPLATE_PATH + "stacked_column.erb").read

		strJS = template.eruby(assigns)
		strJS		
	end

	post "/get_case_sla" do
		startDate = params[:start_date]
		endDate = params[:end_date]
		team = params[:team]
		container = params[:container]
		assigns = getCaseSLAChart(team, startDate, endDate, container, "week")
		template = File.new(TEMPLATE_PATH + "stacked_column.erb").read

		strJS = template.eruby(assigns)
		puts strJS
		strJS		
	end

	post "/get_ttr_severity" do
		startDate = params[:start_date]
		endDate = params[:end_date]
		team = params[:team]
		container = params[:container]
		assigns = getTTRSeverityChart(team, startDate, endDate, container, "week")
		template = File.new(TEMPLATE_PATH + "stacked_grouped_column.erb").read

		strJS = template.eruby(assigns)
		puts strJS
		strJS		
	end

	get :quality do
		render '/war_room_reports/quality', :layout => 'application'
  end
  get :content_management do
		render '/war_room_reports/content_management', :layout => 'application'
  end
  get :hot_case do
		render '/war_room_reports/hot_case', :layout => 'application'
  end
  get :forum_leads do
		render '/war_room_reports/forum_leads', :layout => 'application'
  end

end
