#Rack::Attack.enabled = false if Rails.env.production?

rack_attack_logger = Logger.new(Rails.root.join('log', 'rack_attack.log'))

ActiveSupport::Notifications.subscribe(/rack\.attack/) do |name, start, finish, request_id, payload|
  req = payload[:request]
  if [:throttle, :blocklist].include?(req.env["rack.attack.match_type"])
    rack_attack_logger.warn("[#{req.env["rack.attack.match_type"]}] IP: #{req.ip} | Path: #{req.path} | Rule: #{req.env["rack.attack.matched"]}")
  end
end
