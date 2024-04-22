module StatisticsHelper
  def format_statistic_title(title)
    title = title.to_s.gsub("_", " ")
    title = title.to_s.split.map(&:capitalize).join(' ')
    title.gsub!("Vcpu", "VCPU")
    title.gsub!("Ram", "RAM")
    title.gsub!("Vm", "VM")
    title
  end
end
