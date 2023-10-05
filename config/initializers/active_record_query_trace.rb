Rails.logger.info "====================================> Rails.env=#{Rails.env}"
if Rails.env.development?
  Rails.logger.info "ActiveRecordQueryTrace.enabled"
  ActiveRecordQueryTrace.enabled = true
  # Optional: other gem config options go here
  ActiveRecordQueryTrace.level = :full # default
  ActiveRecordQueryTrace.colorize = :light_purple
end