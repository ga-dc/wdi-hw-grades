require 'sinatra'
require 'rest-client'
require 'json'
require 'google_drive'
require './env' if File.exists?('env.rb')
require 'pry'

enable :sessions
set :session_secret, ENV['GH_SESSION_SECRET']

CLIENT_ID = ENV['GH_BASIC_CLIENT_ID']
CLIENT_SECRET = ENV['GH_BASIC_SECRET_ID']
URL = ENV['GH_URL']

get '/' do
  session['access_token'] ||= ''
  @client_id = CLIENT_ID
  @access_token = session['access_token']
  @url = URL
  @user_name = session['user_name']
  @avatar_url = session['avatar_url']
  erb :index
end

get '/grades' do
  if session['user_name']
    client = Google::APIClient.new
    auth = client.authorization
    auth.client_id = ENV['GOOGLE_CLIENT_ID']
    auth.client_secret = ENV['GOOGLE_SECRET']
    auth.scope =
      "https://www.googleapis.com/auth/drive " +
      "https://spreadsheets.google.com/feeds/"
    auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
    auth.refresh_token = ENV['GOOGLE_REFRESH_TOKEN']
    auth.fetch_access_token!
    sesh = GoogleDrive.login_with_oauth(auth.access_token)
    ws = sesh.spreadsheet_by_key(ENV['SPREADSHEET_KEY']).worksheets[1]
    (2..27).each do |i|
      un = ws[i, 3]
      if un.downcase == session['user_name'].downcase
        @missing = []
	@grade = ws[i,4]
	for col in 5..ws.num_cols
          if ws[i,col] != "1"
            @missing << ws[1,col]
	  end
	end
      end
    end
  end
  {missing: @missing, grade: @grade}.to_json
end

get '/logout' do
  session.clear
  redirect to('/')
end

get '/callback' do
  session_code = request.env['rack.request.query_hash']['code']
  result = RestClient.post('https://github.com/login/oauth/access_token', {
      :client_id => CLIENT_ID,
      :client_secret => CLIENT_SECRET,
      :code => session_code
  },  :accept => :json)
  session['access_token'] = JSON.parse(result)['access_token']
  user = JSON.parse(RestClient.get('https://api.github.com/user?access_token=' + session['access_token']))
  session['user_name'] = user['login']
  session['avatar_url'] = user['avatar_url']
  redirect to('/');
end
