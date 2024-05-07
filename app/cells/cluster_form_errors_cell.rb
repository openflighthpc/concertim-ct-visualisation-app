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

class ClusterFormErrorsCell < Cell::ViewModel
  def show(cluster)
    @cluster = cluster
    render
  end

  private

  def attributes_without_input_field
    [:team]
  end

  def has_input_field_errors?
    input_field_error_count > 0
  end

  def input_field_error_count
    if @cluster.errors.any?
      # If the cluster has any errors set against it, it is expected that these
      # will contain any field errors too.
      @cluster.errors.count - inputless_error_count

    elsif @cluster.fields.any? { |f| !f.errors.empty? }
      # If the cluster does not have any errors, it is still possible that the
      # fields do.  These can be set from the cluster builder response.
      @cluster.fields
              .select { |f| !f.errors.empty? }
              .map { |f| f.errors.count }
              .sum
    else
      0
    end
  end

  def has_errors_without_input_field?
    @cluster.errors.any? && attributes_without_input_field.any? { |attribute| !@cluster.errors[attribute].empty? }
  end

  def inputless_error_count
    attributes_without_input_field.select { |attribute| !@cluster.errors[attribute].empty? }.length
  end

  def inputless_errors_text
    @cluster.errors.select { |error| attributes_without_input_field.include?(error.attribute) }
            .map(&:full_message)
            .join("; ")

  end
end
