#
# Copyright (c) 2019 Alces Software
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#  * Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

module NodeattrUtils
  module NodeParser
    NAME = /\w+/
    RANGE = /\[(\d+([,-]\d+)*)\]/ # Exclude invalid: [] [,] [1-] etc...
    SECTION = /#{NAME}(#{RANGE})?/
    EXTERNAL_COMMA = /,(?![^\[]*\])/
    GENERAL_REGEX = /\A#{SECTION}(,#{SECTION})*\Z/
    RANGE_REGEX = /\A(#{NAME})#{RANGE}\Z/

    def self.expand(nodes_string)
      return [] if nodes_string.nil? || nodes_string.empty?
      error_if_invalid_node_syntax(nodes_string)
      nodes_string.split(EXTERNAL_COMMA)
                  .each_with_object([]) do |node, nodes|
        if match = node.match(RANGE_REGEX)
          prefix, ranges = match[1,2]
          ranges.split(',').each do |range|
            if range.match(/-/)
              nodes.push(*expand_range(prefix, range))
            else
              nodes.push("#{prefix}#{range}")
            end
          end
        else
          nodes.push(node)
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

    def self.expand_range(prefix, range)
      min, max = range.split('-')
      raise NodeSyntaxError, <<~ERROR if min > max
        '#{range}' the minimum index can not be greater than the maximum
      ERROR
      (min.to_i .. max.to_i).map do |num|
        sprintf("#{prefix}%0#{min.length}d", num.to_s)
      end
    end
  end
end
