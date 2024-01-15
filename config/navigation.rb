SimpleNavigation::Configuration.run do |navigation|
  url_helpers = Rails.application.routes.url_helpers
  navigation.selected_class = 'current'

  navigation.items do |primary|

    if user_signed_in?
      if !current_user.root?
        user = user_presenter(current_user)
        primary.item :user_credits, "Available credits: #{user.formatted_credits}", nil,
                     align: :right
        primary.item :user_cost, "Total cost so far this billing period: #{user.currency_cost}", nil,
                     :link_html => {:title => "Current billing period: #{user.billing_period}"},
                     align: :right
      end

      primary.item :youraccount, "#{current_user.name}", '#',
        align: :right,
        icon: :youraccount,
        highlights_on: %r(/accounts|/key_pairs|/invoices) do |acc|
          acc.item :acc_details, 'Account details', url_helpers.edit_user_registration_path, :icon => :details, :link => {:class => 'details'}
          unless current_user.root?
            acc.item :view_invoices, "View invoices", url_helpers.invoices_path,
              icon: :reports,
              link_html: {title: "View invoices"}

            acc.item :acc_details, 'Manage key-pairs', url_helpers.key_pairs_path,
                     :icon => :key, :link => {:class => 'details'}
          end
          acc.item :acc_logout, 'Log out', url_helpers.destroy_user_session_path, :icon => :logout, :link => {:class => 'logout'}
        end

      primary.item :infra_racks_list, 'Rack view', url_helpers.interactive_rack_views_path, icon: :infra_racks, :link => {class: 'infra_racks'}

      if current_user.root?
        primary.item :config, 'Cloud environment', url_helpers.cloud_service_config_path,
          icon: :config,
          highlights_on: %r(/cloud-env/configs)
      end

      if current_user.can?(:manage, User)
        primary.item :config, 'Users', url_helpers.users_path,
          icon: :users,
          highlights_on: %r(/users)
      end

      if current_user.can?(:manage, Setting)
        primary.item :config, 'Settings', url_helpers.edit_settings_path,
          icon: :config,
          highlights_on: %r(/settings)
      end

      if current_user.can?(:read, ClusterType)
        html_options = {}
        if !current_ability.enough_credits_to_create_cluster?
          html_options[:class] = "limited-action-icon"
          html_options[:title] = "You must have at least #{Rails.application.config.cluster_credit_requirement} credits to create a cluster"
        end

        primary.item :cluster_types, 'Launch cluster', url_helpers.cluster_types_path,
          icon: :racks,
          html: html_options,
          highlights_on: %r(/cloud-env/(cluster-types|clusters))
      end
    else
      primary.item :login, 'Log in', url_helpers.new_user_session_path,
        icon: :login,
        align: :right,
        highlights_on: %r(/accounts/sign_in)
    end
  end
end
