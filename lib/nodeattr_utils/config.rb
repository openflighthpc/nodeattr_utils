# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of flight-metal.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# This project is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with this project. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on flight-account, please visit:
# https://github.com/alces-software/flight-metal
#===============================================================================

require 'flight_config'
require 'nodeattr_utils/exceptions'

module NodeattrUtils
  class Config
    include FlightConfig::Updater

    def self.path(_cluster)
      raise NotImplementedError
    end

    def __data__
      super().tap { |d| d.set_if_empty(:groups, value: ['orphan']) }
    end

    def cluster
      __inputs__.first
    end

    def raw_groups
      __data__.fetch(:groups)
    end

    def raw_nodes
      __data__.fetch(:nodes, default: {})
    end

    def nodes_list
      raw_nodes.keys
    end

    def groups_hash
      raw_groups.reject(&:nil?).map do |group|
        [group, group_index(group)]
      end.to_h
    end

    def group_index(group)
      return nil if group.nil?
      raw_groups.find_index(group)
    end

    def groups_for_node(node)
      __data__.fetch(:nodes, node, default: []).dup.tap do |groups|
        groups.push 'orphan' if groups.empty?
      end
    end

    def nodes_in_group(group)
      nodes_list.select { |node| groups_for_node(node).include?(group) }
    end

    def nodes_in_primary_group(group)
      nodes_list.select { |n| groups_for_node(n).first == group }
    end

    def add_group(group_name)
      return if raw_groups.include?(group_name)
      __data__.append(group_name, to: :groups)
    end

    def remove_group(group_name)
      error_if_removing_orphan_group(group_name)
      nodes_list.select { |n| groups_for_node(n).first == group_name }
                .join(',')
                .tap { |node_str| remove_nodes(node_str) }
      __data__.fetch(:groups).map! { |g| g == group_name ? nil : g }
    end

    def add_nodes(node_string, groups: [])
      groups = groups.is_a?(Array) ? groups : [groups]
      add_group(groups.first) unless groups.empty?
      NodeattrUtils::Nodes.expand(node_string).each do |node|
        __data__.set(:nodes, node, value: groups)
      end
    end

    def remove_nodes(node_string)
      NodeattrUtils::Nodes.expand(node_string).map do |node|
        __data__.delete(:nodes, node)
      end
    end

    def orphans
      nodes_in_group('orphan')
    end

    private

    def error_if_removing_orphan_group(group)
      return unless group == 'orphan'
      raise RemovingOrphanGroupError, <<~ERROR.chomp
        Can not remove the orphan group
      ERROR
    end
  end
end

