module Fleece
  class Cluster
    class FieldPresenter < Emma::Presenter
      delegate_missing_to :o

      MAPPED_FIELD_TYPES = {
        "string" => "text_field", "number" => "number_field", "comma_delimited_list" => "text_area",
        "json" => "text_area", "boolean" => "check_box"
      }

      def form_field_type
        allowed_values? ? 'select' : "#{MAPPED_FIELD_TYPES[type]}"
      end

      def select_box?
        form_field_type == 'select'
      end

      def form_label(form)
        classes = %w(required_field)
        classes << 'label_with_errors' unless o.valid?
        form.label id.to_sym, label, class: classes.join(' '), title: form_description
      end

      def error_message(form)
        return nil if o.valid?
        h.tag.span(o.errors.messages_for(:value).to_sentence, class: 'error-message')
      end

      def form_input(form)
        if select_box?
          form.send(form_field_type, :value, allowed_values, {prompt: true}, form_options)
        else
          form.send(form_field_type, :value, form_options)
        end
      end

      def constraint_text
        if constraints.any?
          content = constraint_names.map {|name| constraints[name][:description] }.join(". ")
          h.tag.div(content, class: 'constraint-text')
        end
      end

      def form_options
        options = {
          required: form_field_type != 'check_box',
          class: 'new-cluster-field',
          name: "fleece_cluster[cluster_params][#{id}]",
          id: "fleece_cluster_cluster_params_#{id}"
        }.with_indifferent_access
        unless allowed_values?
          options[:placeholder] = form_placeholder
          options = options.merge(required_length).merge(step).merge(min_max).merge(allowed_pattern)
        end
        options
      end

      def form_description
        details = description
        details << "\nThis field cannot be changed once set." if immutable
        details << "\nThis field will be hidden from users." if hidden
        details
      end

      def min_max
        return {} unless type == "number"

        get_constraint_details("range")
      end

      def required_length
        return {} unless %w[string json comma_delimited_list].include?(type)

        required = get_constraint_details("length")
        required.keys.each do |key|
          required["#{key}length".to_sym] = required.delete(key)
        end

        required
      end

      def allowed_pattern
        return {} unless type == "string"

        pattern = get_constraint_details("allowed_pattern")
        return {} if pattern.empty?

        { pattern: pattern }
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
end
