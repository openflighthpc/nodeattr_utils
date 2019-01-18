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
    NAME = '\w+'
    RANGE = '\[[0-9]+.*[0-9]+\]'
    GENERAL_REGEX = /#{NAME}(#{RANGE})?$/
    RANGE_REGEX = /#{NAME}#{RANGE}/

    def self.expand(nodes_string)
      error_if_invalid_node_syntax(nodes_string)
      nodes = [nodes_string]
      new_nodes = []
      nodes.each do |node|
        if node.match(RANGE_REGEX)
          m = node.match(/^(.*)\[(.*)\]$/)
          prefix = m[1]
          suffix = m[2]
          ranges = suffix.split(',')
          ranges.each do |range|
            if range.match(/-/)
              num_1, num_2 = range.split('-')
              # chomp here is in case num_1 consists only of 0's
              # in that case, e.g. node[000-001], the padding should be 1 char shorter
              # than all the leading 0s in num_1, e.g. '00'
              padding = num_1.chomp('0').match(/^0+/)
              unless num_1 <= num_2
                $stderr.puts "Invalid node range #{range}"
                exit
              end
              (num_1.to_i .. num_2.to_i).each do |num|
                new_nodes.push(sprintf("%s%0#{padding.to_s.length + 1}d", prefix, num))
              end
            else
              new_nodes << "#{prefix}#{range}"
            end
          end
          nodes.delete(node)
        end
      end
      nodes = nodes + new_nodes
      return nodes
    end

    private_class_method

    def self.error_if_invalid_node_syntax(str)
      return if GENERAL_REGEX.match?(str)
      raise NodeSyntaxError, <<~ERROR
        #{str.inspect} does not match a range of nodes syntax
      ERROR
    end
  end
end
