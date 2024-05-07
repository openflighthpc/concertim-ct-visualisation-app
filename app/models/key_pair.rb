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

class KeyPair
  include ActiveModel::API

  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            length: { maximum: 255 }

  validates :fingerprint,
            presence: true,
            length: { maximum: 255 }

  validates :key_type,
            presence: true,
            inclusion: { in: ["ssh", "x509"], message: "%{value} is not a valid type" }

  validates :user,
            presence: true

  ####################################
  #
  # Attributes
  #
  ####################################

  attr_accessor :name, :fingerprint, :key_type, :private_key, :public_key, :user

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(user:, name: nil, fingerprint: nil, key_type: "ssh", public_key: nil, private_key: nil)
    @user = user
    @name = name
    @fingerprint = fingerprint
    @key_type = key_type
    @public_key = public_key
    @private_key = private_key
  end
end
