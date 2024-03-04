class Cluster
  class FieldPresenter < Presenter
    delegate_missing_to :o

    MAPPED_FIELD_TYPES = {
      "string" => "text_field", "number" => "number_field", "comma_delimited_list" => "text_area",
      "json" => "text_area", "boolean" => "check_box"
    }.freeze

    # Map a custom constraint name to the name of the cloud asset we want to
    # use to populate the select tag with.
    #
    # E.g., if a field has a constraint of `glance.image` it will be rendered
    # as a select tag containing the cloud asset `images` as option tags.
    #
    # If a field has a constraint of `allowed_values` that takes precedence.
    CONSTRAINTS_TO_ASSETS = {
      "glance.image" => "images",
      "neutron.network" => "networks",
      "nova.flavor" => "flavors",
      "nova.keypair" => "keypairs",
      "sahara.plugin" => "sahara.plugins",
      "sahara.image" => "sahara.images",
      "sahara.cluster_template" => "sahara.cluster_templates",
    }.freeze

    def initialize(object, view_context, cloud_assets)
      super(object, view_context)
      @cloud_assets = cloud_assets
    end

    def form_field_type
      if select_box?
        'select'
      elsif type == 'string' && hidden
        'password_field'
      else
        MAPPED_FIELD_TYPES[type]
      end
    end

    def select_box?
      return true if allowed_values?

      CONSTRAINTS_TO_ASSETS.any? do |constraint, cloud_asset|
        constraints.has_constraint?(constraint) && @cloud_assets.key?(cloud_asset)
      end
    end

    def form_label(form)
      classes = %w(required_field)
      classes << 'label_with_errors' unless o.errors.empty?
      form.label id.to_sym, label, class: classes.join(' '), title: label_tooltip
    end

    def error_message(form)
      return nil if o.errors.empty?
      if o.errors.include?(:constraint)
        h.tag.span(o.errors.full_messages.to_sentence, class: 'error-message')
      else
        h.tag.span(o.errors.messages_for(:value).to_sentence, class: 'error-message')
      end
    end

    def form_input(form)
      if select_box?
        values =
          if allowed_values?
            allowed_values
          else
            _, cloud_asset = CONSTRAINTS_TO_ASSETS.detect do |constraint, cloud_asset|
              constraints.has_constraint?(constraint)
            end
            @cloud_assets[cloud_asset].map { |a| [a["name"], a["id"]] }
          end
        form.send(form_field_type, :value, values, {prompt: true}, form_options)
      else
        form.send(form_field_type, :value, form_options)
       end
    end

    def constraint_text
      unless constraints.empty?
        content = constraints.map(&:description).compact.join(". ")
        h.tag.div(content, class: 'constraint-text')
      end
    end

    def form_options
      options = {
        required: form_field_type != 'check_box',
        class: 'new-cluster-field',
        name: "cluster[cluster_params][#{id}]",
        id: "cluster_cluster_params_#{id}"
      }.with_indifferent_access
      unless allowed_values?
        options[:placeholder] = form_placeholder
        options = options.merge(required_length).merge(step).merge(min_max).merge(allowed_pattern)
      end
      options
    end

    def label_tooltip
      details = ""
      details << "\nThis field cannot be changed once set." if immutable
      details << "\nThis field will be hidden from users." if hidden
      details
    end

    def form_description
      h.tag.div(description, class: 'cluster-field-description')
    end

    def min_max
      return {} unless type == "number"

      constraints[:range]&.definition || {}
    end

    def required_length
      return {} unless %w[string json comma_delimited_list].include?(type)

      required = constraints[:length]&.definition || {}
      required.keys.each do |key|
        required["#{key}length".to_sym] = required.delete(key)
      end

      required
    end

    def allowed_pattern
      return {} unless type == "string"

      pattern = constraints[:allowed_pattern]
      if pattern.nil?
        {}
      else
        { pattern: pattern.definition }
      end
    end

    # possible future improvement: have JS for creating text boxes for each array/ hash option instead of
    # expecting user to input text in correct format
    def form_placeholder
      return default if default

      case type
      when 'comma_delimited_list'
        'A list of choices separated by commas: choice1,choice2,choice3'
      when 'json'
        'Collection of keys and values: {"key1":"value1", "key2":"value2"}'
      end
    end
  end
end
