SimpleNavigation::Configuration.run do |navigation|
  navigation.selected_class = 'current'

  navigation.items do |primary|

    if user_signed_in?
      if !current_user.root?
        user = user_presenter(current_user)
        primary.item :user_cost, "Total cost so far this billing period: #{user.cost}", nil,
                     :link_html => {:title => "Current billing period: #{user.billing_period}"},
                     align: :right
      end

      primary.item :youraccount, "#{current_user.name}", '#',
        align: :right,
        icon: :youraccount,
        highlights_on: /\/users/ do |acc|
          acc.item :acc_details, 'Account details', uma_engine.edit_user_registration_path, :icon => :details, :link => {:class => 'details'}
          unless current_user.root?
            acc.item :acc_details, 'Manage key-pairs', Rails.application.routes.url_helpers.key_pairs_path,
                     :icon => :key, :link => {:class => 'details'}
          end
          acc.item :acc_logout, 'Log out', uma_engine.destroy_user_session_path, :icon => :logout, :link => {:class => 'logout'}
        end

      primary.item :infra_racks_list, 'Rack view', ivy_engine.irv_path, icon: :infra_racks, :link => {class: 'infra_racks'}

      if current_user.root?
        primary.item :fleece_config, 'Cloud environment', Rails.application.routes.url_helpers.fleece_config_path,
          icon: :config,
          highlights_on: /\/cloud-env\/configs/
      end

      if current_user.can?(:create, Fleece::Cluster)
        primary.item :fleece_cluster_types, 'Launch cluster', Rails.application.routes.url_helpers.fleece_cluster_types_path,
          icon: :racks,
          highlights_on: /\/cloud-env\/(cluster-types|clusters)/
      end
    else
      primary.item :login, 'Log in', uma_engine.new_user_session_path,
        icon: :login,
        align: :right,
        highlights_on: /\/users\/sign_in/
    end
  end
end
