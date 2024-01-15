class Setting < ApplicationRecord
  SETTINGS = %w(metric_refresh_interval)
  SETTINGS.each do |key|
    define_method(key) do
      settings[key]
    end
    define_method("#{key}=") do |val|
      settings[key] = val
    end
  end

  validate do
    settings.keys.each do |key|
      errors.add(key.to_sym, "unknown key") unless SETTINGS.include?(key)
    end
  end

  validates :metric_refresh_interval,
    presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 15}

  before_save do
    self.metric_refresh_interval = self.metric_refresh_interval.to_i
  end
end
