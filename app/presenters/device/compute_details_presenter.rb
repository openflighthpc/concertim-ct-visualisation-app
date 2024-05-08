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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

class Device::ComputeDetailsPresenter < Device::DetailsPresenter

  delegate :public_ips, :private_ips, :login_user, :ssh_key, :volume_details, to: :o

  def additional_details
    [].tap do |d|
      if has_login_details?
        d << [
          'Access details:',
          {
            'Login user:': login_user || 'Unknown',
            'Public IPs:': public_ips,
            'Private IPs:': private_ips,
            'SSH key:': ssh_key || 'Unknown'
          }
        ]
      end

      if has_volume_details?
        d << [
          'Volume details:', volume_details
        ]
      end

    end
  end


  private

  def has_login_details?
    public_ips || private_ips || ssh_key || login_user
  end

  def has_volume_details?
    !volume_details.empty?
  end

end
