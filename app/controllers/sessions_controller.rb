class SessionsController < ApplicationController

  def create
    @uid = auth_hash['uid']
    @name = auth_hash['info']['name']
    @token = auth_hash['credentials']['token']
    uri = URI('https://graph.facebook.com/me/inbox')
    params = {limit: 1, access_token: @token}
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)
    message = JSON.parse(res.body)
    @to_usr =  message['data'][0]['to']['data'][1]['name']
    comment_data = message['data'][0]['comments']['data']
    @messages = Array.new
    @messages.concat(comment_data)
    uri = URI(message['data'][0]['comments']['paging']['next'])
    (1..50).each do |i|
      res = Net::HTTP.get_response(uri)
      break unless res.is_a?(Net::HTTPSuccess)
      message = JSON.parse(res.body)
      comment_data = message['data']
      @messages = comment_data + @messages
      uri = URI(message['paging']['next'])
      puts "Next page" + message['paging']['next']
    end
  end#create

  protected
  def auth_hash
    request.env['omniauth.auth']
  end#auth_hash
end
