object @rack
attributes :id, :name
attribute :u_height => :uHeight
child(:rack_chassis) do 
  attribute :id, :facing
  attribute :row_count => :rows
  attribute :slot_count => :slots
  attribute :column_count => :columns
  attribute :rack_start_u => :uStart
  attribute :rack_end_u => :uEnd
  attribute :meta_data => :template
  node(:machines) do |chassis|
    [].tap do |el|
      chassis.chassis_rows.slots.each do |slot|
        if slot.device.nil?
          el << {}
        else
          el << { 
           :id => slot.device[:id],
           :name => slot.device.name,
           :row => slot.chassis_row.row_number,
           :col => slot.chassis_row_location,
          }
        end
      end    
    end
  end
end
