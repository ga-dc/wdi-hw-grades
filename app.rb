require 'sinatra'
require 'sinatra/reloader'
require 'httparty'
require 'json'
require 'cgi'
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
    ws = sesh.spreadsheet_by_key(ENV['SPREADSHEET_KEY']).worksheets[2]
    (4..47).each do |i|
      un = ws[i, 6]
      if un.downcase == session['user_name'].downcase
        @missing = []
	@grade = "#{100 - ws[i,7].to_i}%"
	for col in 9..ws.num_cols
          if ws[i,col] != "c" && ws[i,col]  != "i"
	    wd = ws[1,col].split(":")
            @missing << "Week #{wd[0]}, Day #{wd[1]}"
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
  result = HTTParty.post('https://github.com/login/oauth/access_token', :body => {
      :client_id => CLIENT_ID,
      :client_secret => CLIENT_SECRET,
      :code => session_code
  })
  session['access_token'] = CGI::parse(result)['access_token'][0]
  user = JSON.parse(HTTParty.get('https://api.github.com/user?access_token=' + session['access_token']).body)
  session['user_name'] = user['login']
  session['avatar_url'] = user['avatar_url']
  redirect to('/');
end
