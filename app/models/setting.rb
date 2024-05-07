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

class Setting < ApplicationRecord
  SETTINGS = %w(metric_refresh_interval)
  SETTINGS.each do |key|
    define_method(key) do
      settings[key]
    end
    define_method("#{key}=") do |val|
      settings[key] = val
    end
  end

  validate do
    settings.keys.each do |key|
      errors.add(key.to_sym, "unknown key") unless SETTINGS.include?(key)
    end
  end

  validates :metric_refresh_interval,
    presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 15}

  before_save do
    self.metric_refresh_interval = self.metric_refresh_interval.to_i
  end
end
