module HttpRequests
  # Provides simple API to sync results from a HTTP response body to a model.
  #
  #   class Person
  #     attr_accessor :age
  #     attr_accessor :name
  #   end
  #
  #   class Result
  #     include HttpRequests::ResultSyncer
  #
  #     # Sync the "age" attribute in the body to the "age" attribute on the model.
  #     property :age
  #     # Sync the "title" attribute in the body to the "name" attribute on the model.
  #     property :name, from: :title
  #
  #     # Optionally add ActiveModel validations.
  #     validates :age, numericality: { greater_than_or_equal_to: 18 }
  #     validates :name, presence: true
  #   end
  #
  #   body = {"age": 21, "title": "Bob"}
  #   result = Result.from(body)
  #   result.validate!
  #   person = Person.new
  #   result.sync(person)
  #   person.age == 21 #=> true
  #   person.name == "Bob" #=> true
  #
  # This is inspired by https://github.com/trailblazer/reform and
  # https://github.com/apotonick/disposable.  They are designed to work with
  # two way syncing which is not what we have here.  If we need something more
  # complicated than this, it might be worth reconsidering adding one or both
  # of the above as dependencies.
  module ResultSyncer
    extend ActiveSupport::Concern

    included do
      include ActiveModel::API
      cattr_accessor :properties
      self.properties = {}
    end

    class_methods do
      def property(attr, from: nil, context: nil)
        attr_accessor(attr)
        properties[from || attr] = {to: attr, context: context}
      end

      # Load properties from the given source.
      def from(source)
        new.tap do |instance|
          properties.each do |from, prop|
            to = prop[:to]
            instance.send("#{to}=", source[from.to_s])
          end
        end
      end
    end

    # Sync and persist the properties to the model.  If `context` is given,
    # only properties for that context will be synced.
    def sync(model, context=nil)
      properties.each do |_, prop|
        to = prop[:to]
        if context.nil? || context == prop[:context]
          model.send("#{to}=", send(to))
        end
      end
      model.save!
    end
  end
end
