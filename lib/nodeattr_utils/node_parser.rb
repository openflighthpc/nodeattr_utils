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
    EXTERNAL_COMMA = /,(?![^\[]*\])/
    CHAR = /[^\s\=\,\[]/
    NAME = /#{CHAR}+/
    RANGE = /\[(\d+([,-]\d+)*)\]/ # Exclude invalid: [] [,] [1-] etc...
    SECTION = /#{NAME}(#{RANGE})?/
    GENERAL_REGEX = /\A#{SECTION}(,#{SECTION})*\Z/
    RANGE_REGEX = /\A(#{NAME})#{RANGE}\Z/

    def self.expand(nodes_string)
      return [] if nodes_string.nil? || nodes_string.empty?
      error_if_invalid_node_syntax(nodes_string)
      nodes_string.split(EXTERNAL_COMMA)
                  .each_with_object([]) do |section, nodes|
        if match = section.match(RANGE_REGEX)
          prefix, ranges = match[1,2]
          ranges.split(',').each do |range|
            nodes.push(*expand_range(prefix, range))
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

    def self.expand_range(prefix, range)
      return ["#{prefix}#{range}"] unless range.include?('-')
      min_str, _ = indices = range.split('-')
      min, max = indices.map(&:to_i)
      raise NodeSyntaxError, <<~ERROR if min > max
        '#{range}' the minimum index can not be greater than the maximum
      ERROR
      (min .. max).map do |num|
        sprintf("#{prefix}%0#{min_str.length}d", num)
      end
    end
  end
end
