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

RSpec.describe NodeattrUtils::NodeParser do
  def pad_int(int, width: 2)
    sprintf("%0#{width}d", int)
  end

  def index_range(indices)
    (indices.first..indices.last)
  end

  def expect_expand(*args)
    expect(described_class.expand(*args))
  end

  def expect_collapse(*args)
    expect(described_class.collapse(*args))
  end

  shared_examples 'parses the nodes' do
    describe '::expand' do
      it 'expands the nodes' do
        expect_expand(nodes_string).to contain_exactly(*nodes)
      end
    end

    describe '#collapse' do
      it 'collapses the nodes' do
        expect_collapse(*nodes).to eq(nodes_string)
      end
    end
  end

  context 'with a single node input' do
    ['node', 'node1', 'node01'].each do |node|
      context "with a single node: #{node}" do
        let(:nodes_string) { node }
        let(:nodes) { [node] }

        include_examples 'parses the nodes'
      end
    end
  end

  context 'with a continuous, non-leading zero range' do
    let(:indices) { [0, 20] }
    let(:nodes) { index_range(indices).map { |i| "node#{i}" } }
    let(:nodes_string) { "node[#{indices.first}-#{indices.last}]" }

    include_examples 'parses the nodes'
  end

  context 'with a continuous, leading zero range' do
    let(:indices) { [0, 20] }
    let(:nodes) do
      index_range(indices).map { |i| "node#{pad_int(i)}" }
    end
    let(:nodes_string) do
      "node[#{pad_int(indices.first)}-#{pad_int(indices.last)}]"
    end

    include_examples 'parses the nodes'
  end

  context 'with a discrete range of nodes' do
    let(:indices) { ['0', '00', '1', '02', '3', '4', '6', '007'] }
    let(:nodes) { indices.map { |i| "node#{i}" } }
    let(:nodes_string) { "node[#{indices.join(',')}]" }

    include_examples 'parses the nodes'
  end

  context 'with a complex leading zero, continuous range' do
    let(:width) { 3 }
    let(:indices) { [4, 19] }
    let(:nodes) do
      index_range(indices).map { |i| "node#{pad_int(i, width: width)}" }
    end
    let(:nodes_string) do
      # The first leading zero is outside the range
      min = pad_int(indices.first, width: width - 1)
      max = pad_int(indices.last, width: width - 1)
      "node0[#{min}-#{max}]"
    end

    include_examples 'parses the nodes'
  end

  context 'with a compound continuous/discrete range' do
    let(:cont_indices) { [9, 101] }
    let(:cont_nodes) do
      index_range(cont_indices).map { |i| "node#{pad_int(i)}" }
    end
    let(:cont_str) do
      "#{pad_int(cont_indices.first)}-#{pad_int(cont_indices.last)}"
    end

    let(:prefix_indices) { [103, 105, 107, 109] }
    let(:suffix_indices) { [1, 2, 4, 5, 8] }
    # NOTE: The prefix/suffix are out of order here b/c it shouldn't make
    # a difference to the spec
    let(:discrete_nodes) do
      [suffix_indices, prefix_indices].flatten
                                      .map { |i| "node#{i}" }
    end

    let(:nodes) do
      [cont_nodes, discrete_nodes].flatten
    end
    let(:nodes_string) do
      prefix = prefix_indices.join(',')
      suffix = suffix_indices.join(',')
      "node[#{prefix},#{cont_str},#{suffix}]"
    end

    include_examples 'parses the nodes'
  end

  context 'with multiple single nodes' do
    let(:nodes) { ['node', 'slave', 'login'] }
    let(:nodes_string) { nodes.join(',') }

    include_examples 'parses the nodes'
  end

  describe '::expand' do
    context 'with a invalid node input' do
      [
        '%%%', 'n[1-9', 'n4]', 'n[c]', 'n[1,c,2]', 'n[2-1]', 'n[-2]', 'n[]',
        'n[1,,2]', 'n[1,-2]', 'n[,]', 'n[-]'
      ].each do |node|
        it "#{node.inspect} raises NodeSyntaxError" do
          expect do
            described_class.expand(node)
          end.to raise_error(NodeattrUtils::NodeSyntaxError)
        end
      end
    end

    context 'with a empty inputs' do
      ['', nil].each do |node|
        it "#{node.inspect} returns an empty array" do
          expect_expand(node).to eq([])
        end
      end
    end
  end
end
