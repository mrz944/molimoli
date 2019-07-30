require 'openpayu'

OpenPayU::Configuration.configure do |config|
  config.merchant_pos_id  = ENV['PAYU_POS_ID']
  config.signature_key    = ENV['PAYU_SIGNATURE_KEY']
  config.algorithm        = 'MD5'
  config.service_domain   = 'payu.com'
  config.protocol         = 'https'
  config.env              = 'secure'
  config.order_url        = ''
  config.notify_url       = ''
  config.continue_url     = ''
end
