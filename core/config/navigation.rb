SimpleNavigation::Configuration.run do |navigation|
  navigation.selected_class = 'current'

  navigation.items do |primary|

    if user_signed_in?
      primary.item :youraccount, "#{current_user.firstname} #{current_user.surname}", '#',
        align: :right,
        icon: :youraccount,
        highlights_on: /--\/users/ do |acc|
          acc.item :acc_logout, 'Log out', uma_engine.destroy_user_session_path, :icon => :logout, :link => {:class => 'logout'}
        end

      primary.item :hardware, 'Assets', ivy_irv_path, icon: :hardware do |hw|
        hw.item :hw_racks, 'Racks', ivy_irv_path,
          class: 'menuL2',
          icon: :infra_racks,
          link: {class: 'infra_racks'},
          highlights_on: %r(/irv|/racks) do |rack|
            rack.item :infra_racks_list, 'Rack view', ivy_irv_path, :link => {:class => 'infra_racks'}
          end
      end
    else
      primary.item :login, 'Log in', uma_engine.new_user_session_path,
        icon: :login,
        align: :right,
        highlights_on: /--\/users\/sign_in/
    end
  end
end
