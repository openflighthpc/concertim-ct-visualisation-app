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

require 'faker'

FactoryBot.define do
  factory :invoice, class: 'Invoice' do
    amount { rand(100) }
    balance { rand(100) }
    credit_adj { 0 }
    currency { 'USD' }
    invoice_date { Date.today }
    invoice_id { Faker::Internet.uuid }
    sequence(:invoice_number) { |n| n }
    refund_adj { 0 }
    status { 'COMMITTED' }

    association :account, :with_openstack_details, factory: :team
    items { [] }

    initialize_with { new(attributes) }
  end

  trait :draft do
    status { 'DRAFT' }
  end
end
