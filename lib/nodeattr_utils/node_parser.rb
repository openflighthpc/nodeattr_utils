#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of NodeattrUtils.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# NodeattrUtils is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with NodeattrUtils. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on NodeattrUtils, please visit:
# https://github.com/openflighthpc/nodeattr_utils
#==============================================================================
module NodeattrUtils
  module NodeParser
    EXTERNAL_COMMA = /,(?![^\[]*\])/
    CHAR = /[^\s\=\,\[]/
    NAME = /#{CHAR}+/
    SUFFIX = /#{CHAR}*/
    RANGE = /\[(\d+([,-]\d+)*)\]/ # Exclude invalid: [] [,] [1-] etc...
    SECTION = /#{NAME}(#{RANGE}#{SUFFIX})?/
    GENERAL_REGEX = /\A#{SECTION}(,#{SECTION})*\Z/
    RANGE_REGEX = /\A(#{NAME})#{RANGE}(#{SUFFIX})\Z/

    def self.expand(nodes_string)
      return [] if nodes_string.nil? || nodes_string.empty?
      error_if_invalid_node_syntax(nodes_string)
      nodes_string.split(EXTERNAL_COMMA)
                  .each_with_object([]) do |section, nodes|
        if match = section.match(RANGE_REGEX)
          # match 3 is the 2nd num of the range, used later
          prefix, ranges, _, suffix = match[1,4]
          ranges.split(',').each do |range|
            nodes.push(*expand_range(prefix, range, suffix))
          end
        else
          nodes.push(section)
        end
      end
    end

    private_class_method

    def self.error_if_invalid_node_syntax(str)
      return if GENERAL_REGEX.match?(str)
      raise NodeSyntaxError, <<~ERROR
        #{str.inspect} does not represent a range of nodes
      ERROR
    end

    def self.expand_range(prefix, range, suffix)
      return ["#{prefix}#{range}#{suffix}"] unless range.include?('-')
      min_str, _ = indices = range.split('-')
      min, max = indices.map(&:to_i)
      raise NodeSyntaxError, <<~ERROR if min > max
        '#{range}' the minimum index can not be greater than the maximum
      ERROR
      (min .. max).map do |num|
        sprintf("#{prefix}%0#{min_str.length}d#{suffix}", num)
      end
    end
  end
end
