SimpleNavigation::Configuration.run do |navigation|
  navigation.selected_class = 'current'

  navigation.items do |primary|

    primary.item :youraccount, "#{current_user.firstname} #{current_user.surname}",  '#', align: :right, :icon => :youraccount, :highlights_on => /-\/users/ do |acc|
      acc.item :acc_logout, 'Log out', '#', :icon => :logout, :link => {:class => 'logout'}
    end

    primary.item :hardware, 'Assets', ivy_irv_path, :icon => :hardware do |hw|
      hw.item :hw_racks, 'Racks', ivy_irv_path, :class => 'menuL2', :icon => :infra_racks, :link => {:class => 'infra_racks'}, :highlights_on => %r(/irv|/racks) do |rack|
        rack.item :infra_racks_list, 'Rack view', ivy_irv_path, :link => {:class => 'infra_racks'}
      end
    end
  end
end
