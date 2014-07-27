# see example from http://whatsup.org.il/index.php?name=PNphpBB2&file=viewtopic&t=59750
# Also - the alert areas can be found here - http://www.oref.org.il/1096-he/Pakar.aspx

# require 'httparty'
# require 'json'
# require 'twilio-ruby'
require 'bundler'
Bundler.require

ALERTS_URL = 'http://www.oref.org.il/WarningMessages/alerts.json'
DAN = 157
DEFAULT_SLEEP_INTERVAL = 3 # one second
LONG_SLEEP_INTERVAL = 300 # five minutes

def init_logger
  @logger = Logging.logger['main_logger']
  @logger.add_appenders(
      Logging.appenders.stdout,
      Logging.appenders.file('./log/red_color_alerts.log')
  )
  @logger.level = :info

  # logger.debug "this debug message will not be output by the logger"
  # logger.info "just some friendly advice"
end

def log(level, msg)
  log_msg = Time.now.to_s << ' ' << msg.to_s
  @logger.send(level, log_msg)
end

def init_twilio
  account_sid = 'AC85ec3f804a91244129fcb9651dc0c35d'
  auth_token = '20f38cc2e08fe0f679607d1b104fd7d2'

  # set up a client to talk to the Twilio REST API
  @client = Twilio::REST::Client.new account_sid, auth_token
end

def send_sms(alert)
  # binding.pry
  @client.account.messages.create({
    :from => '+1(720) 961-2140',
    :to => '+972544491208',
    :body => 'Tikush',
    # :body => alert,
  })
rescue => e
  log(:error, e.message << e.backtrace.inspect)
end

def get_alerts(req, url)
  res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }
  JSON.parse(res.body.force_encoding("utf-16"))
rescue => e
  log(:error, e.message << e.backtrace.inspect)
  {'data' => []}
end

def main
  init_logger
  init_twilio
  url = URI.parse(ALERTS_URL)
  req = Net::HTTP::Get.new(url)
  req.add_field('User-Agent', 'Test')
  req.add_field('Content-Type', "application/json; charset=utf-8")

  counter = 0
  while true
    sleep_interval = DEFAULT_SLEEP_INTERVAL
    res = get_alerts(req, url)
    alerts = res['data']
    # alerts = ['157 גשדכגדג']
    alerts.each do |alert|
      log(:info, alerts)
      next unless alert.include?(DAN.to_s)
      send_sms(alert)
      # log(:info, res)
      sleep_interval = LONG_SLEEP_INTERVAL
    end

    sleep(sleep_interval)
    counter += 1
    if counter % 30 == 0
      log(:info, 'still running!')
      counter = 0
    end
  end
end

main

