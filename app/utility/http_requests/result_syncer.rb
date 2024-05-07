#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

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
