LIB_PATH = File.dirname(__FILE__) + '../lib/'
Dir["#{LIB_PATH}/*.rb"].each { |file| require file }

BjsOpsDashboard::App.controllers :rawdata do
  
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
		datatable_structure = RawdataUtil.new.get_datatable_structure(params[:view])
		@rawdata_datatable_json = datatable_structure['datatable'].to_json
		@rawdata_datatable_header = datatable_structure['header']
		render '/rawdata/index', :layout => 'application'
  end

	post '/show_rawdata' do
		result = RawdataUtil.new.get_rawdata(params)
		result
	end

end
