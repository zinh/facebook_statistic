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
    i = 0
    while true do
      res = Net::HTTP.get_response(uri)
      break unless res.is_a?(Net::HTTPSuccess)
      message = JSON.parse(res.body)
      comment_data = message['data']
      # break if no more message
      break if comment_data.blank?
      @messages = comment_data + @messages
      uri = URI(message['paging']['next'])
      puts "Next page: " + message['paging']['next']
      #sleep 5 secs every 50 requests
      i = i + 1 
      sleep(5) if (i%50 == 0)
    end
  end#create

  def get_messsage_raking
    @uid = auth_hash['uid']
    @name = auth_hash['info']['name']
    @token = auth_hash['credentials']['token']
    uri = URI("https://graph.facebook.com/fql")
    params = {access_token: @token}
    #array of hash contains message count, recipients
    @results = Array.new
    user = User.find_or_initialize_by(uid: @uid)
    user.write_attributes(
      name: @name,
      access_token: @token
    )
    user.save
    #User.create(uid: @uid, name: @name, access_token: @token)
    #Get all thread with message count
    query = "select message_count, thread_id FROM thread WHERE folder_id=0 ORDER BY message_count DESC LIMIT 20"
    params[:q] = query
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)
    thread_list = JSON.parse(res.body) 
    #TODO: Catch permission error
    threads = thread_list['data']
    threads.each do |thread|
      thread_info = {message_count: thread['message_count']}
      thread_id = thread['thread_id']
      #query recipient of thread
      query = "select recipients from thread where thread_id=#{thread_id}"
      params[:q] = query
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
      recipient_list = JSON.parse(res.body)
      recipients = recipient_list['data']
      next if (recipients.count > 2)
      first_recv = recipients[0]['recipients']
      recv_uid = (first_recv.select{|r| !r.eql?@uid.to_i}).first
      thread_info[:recv_uid] = recv_uid
      #select receiver name
      query = "select name from user where uid = #{recv_uid}"
      params[:q] = query
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
      user_info = JSON.parse(res.body)
      if user_info['data'][0].blank?
        next
      else
        user_name = user_info['data'][0]['name'] 
        thread_info[:recv_name] = user_name
        @results.push(thread_info)
      end#if
    end#each
  end#get_messsage_raking

  protected
  def auth_hash
    request.env['omniauth.auth']
  end#auth_hash
end
