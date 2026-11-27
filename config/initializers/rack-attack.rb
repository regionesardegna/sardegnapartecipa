Rack::Attack.enabled = true if Rails.env.production?

rack_attack_logger = Logger.new(Rails.root.join("log", "rack_attack.log"))

ActiveSupport::Notifications.subscribe(/rack\.attack/) do |_name, _start, _finish, _request_id, payload|
  req = payload[:request]
  if [:throttle, :blocklist].include?(req.env["rack.attack.match_type"])
    rack_attack_logger.warn("[#{req.env["rack.attack.match_type"]}] IP: #{req.ip} | Path: #{req.path} | Rule: #{req.env["rack.attack.matched"]}")
  end
end

if defined?(Rack::Attack) && ENV["RACK_ATTACK_SAFELIST_IPS"].present?
  ENV["RACK_ATTACK_SAFELIST_IPS"].split(",").map(&:strip).reject(&:blank?).each do |ip|
    Rack::Attack.safelist_ip(ip)
  end
end
