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

class ClusterFormNameCell < Cell::ViewModel
  def show(cluster, form)
    @record = cluster
    @form = form
    @errors = @record.errors
    @attribute = :name
    if has_clustername_parameter?
      # We don't render anything here.  Instead the value provided for the
      # 'clustername' parameter will be used.
    else
      render
    end
  end

  private

  def has_clustername_parameter?
    @record.fields.any? do |field|
      field.id == Cluster::NAME_FIELD
    end
  end

  def label_text
    'Cluster name'
  end

  def f
    @form
  end

  def attribute
    @attribute
  end

  def has_errors?
    @errors.include?(@attribute)
  end

  def label_classes
    "required_field".tap do |classes|
      classes << " label_with_errors" if has_errors?
    end
  end

  def error_message
    @errors.messages_for(@attribute).to_sentence
  end
end
