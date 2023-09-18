class TypeHumanizer

  #
  # Those types where simply "humanizing" the type is not good enough.
  #
  BESPOKE_TEXT_TYPES = {
    'RackChassis'         => 'Chassis',
  }


  def self.humanize(klass)
    klass = klass.to_s.split("::").last
    (BESPOKE_TEXT_TYPES[klass] || klass.titleize.humanize)
  end

end