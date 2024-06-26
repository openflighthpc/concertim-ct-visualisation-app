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

# frozen_string_literal: true

class RecreateGoodJobCronIndexesWithConditional < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
          add_index :good_jobs, [:cron_key, :created_at], where: "(cron_key IS NOT NULL)",
                    name: :index_good_jobs_on_cron_key_and_created_at_cond, algorithm: :concurrently
        end
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
          add_index :good_jobs, [:cron_key, :cron_at], where: "(cron_key IS NOT NULL)", unique: true,
                    name: :index_good_jobs_on_cron_key_and_cron_at_cond, algorithm: :concurrently
        end

        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at
        end
        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at
        end
      end

      dir.down do
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
          add_index :good_jobs, [:cron_key, :created_at],
                    name: :index_good_jobs_on_cron_key_and_created_at, algorithm: :concurrently
        end
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
          add_index :good_jobs, [:cron_key, :cron_at], unique: true,
                    name: :index_good_jobs_on_cron_key_and_cron_at, algorithm: :concurrently
        end

        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at_cond
        end
        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at_cond
        end
      end
    end
  end
end
