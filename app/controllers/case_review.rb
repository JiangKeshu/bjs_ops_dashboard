LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }


BjsOpsDashboard::App.controllers :case_review do
  
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
    render '/case_review/index', :layout => 'application'
  end

	post '/list_agent_cases' do
		agents = params[:users]
		startDate = params[:start_date]
		endDate = params[:end_date]
		team = params[:team]
		
		data = getCaseReviewList(agents, startDate, endDate, team)

		data
	end

	get '/review' do
		caseID = params[:caseID]
		@hashCaseReviewDetail = getCaseReviewDetail(caseID)

		render '/case_review/review', :layout => 'application'
	end
	
	post '/submit' do
		result = submitReview(params)	

		result
	end

end
