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
RSpec.describe NodeattrUtils::NodeParser do
  def pad_int(int, width: 2)
    sprintf("%0#{width}d", int)
  end

  def index_range(indices)
    (indices.first..indices.last)
  end

  describe '::expand' do
    def expect_expand(*args)
      expect(described_class.expand(*args))
    end

    context 'with a invalid node input' do
      # NB: according to genders' specification '=' is invalid in node names
      [
        'n[1-9', 'n[c]', 'n[1,c,2]', 'n[2-1]', 'n[-2]', 'n[]',
        'n[1,,2]', 'n[1,-2]', 'n[,]', 'n[-]', 'no=de[1-10]', 'no[de[1-10]',
        'node[1-10]node[1-10]'
      ].each do |node|
        it "#{node.inspect} raises NodeSyntaxError" do
          expect do
            described_class.expand(node)
          end.to raise_error(NodeattrUtils::NodeSyntaxError)
        end
      end
    end

    shared_examples 'expands the nodes' do
      it 'expands the nodes' do
        expect_expand(nodes_string).to contain_exactly(*nodes)
      end
    end

    context 'with a empty inputs' do
      ['', nil].each do |node|
        it "#{node.inspect} returns an empty array" do
          expect_expand(node).to eq([])
        end
      end
    end

    context 'with a single node input' do
      [
       'node', 'node1', 'node01', 'node*1', 'node1edon', '***', 'n4]'
      ].each do |node|
        it "returns: [#{node}]" do
          expect_expand(node).to contain_exactly(node)
        end
      end
    end

    context 'with a continuous, non-leading zero range' do
      let(:indices) { [0, 20] }
      let(:nodes) { index_range(indices).map { |i| "node#{i}" } }
      let(:nodes_string) { "node[#{indices.first}-#{indices.last}]" }

      include_examples 'expands the nodes'
    end

    context 'with a continuous, leading zero range' do
      let(:indices) { [0, 20] }
      let(:nodes) do
        index_range(indices).map { |i| "node#{pad_int(i)}" }
      end
      let(:nodes_string) do
        "node[#{pad_int(indices.first)}-#{pad_int(indices.last)}]"
      end

      include_examples 'expands the nodes'
    end

    context 'with a discrete range of nodes' do
      let(:indices) { ['0', '00', '1', '02', '3', '4', '6', '007'] }
      let(:nodes) { indices.map { |i| "node#{i}" } }
      let(:nodes_string) { "node[#{indices.join(',')}]" }

      include_examples 'expands the nodes'
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

      include_examples 'expands the nodes'
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

      include_examples 'expands the nodes'
    end

    context 'with multiple single nodes' do
      let(:nodes) { ['node', 'slave', 'login'] }
      let(:nodes_string) { nodes.join(',') }

      include_examples 'expands the nodes'
    end

    context 'with non-standard prefixes' do
      let(:indices) { [0, 20] }
      let(:nodes) { index_range(indices).map { |i| "no*de#{i}" } }
      let(:nodes_string) { "no*de[#{indices.first}-#{indices.last}]" }

      include_examples 'expands the nodes'
    end

    context 'with suffixes' do
      let(:indices) { [0, 20] }
      let(:nodes) { index_range(indices).map { |i| "node#{i}edon" } }
      let(:nodes_string) { "node[#{indices.first}-#{indices.last}]edon" }

      include_examples 'expands the nodes'
    end

    context 'with non-standard suffixes' do
      let(:indices) { [0, 20] }
      let(:nodes) { index_range(indices).map { |i| "node#{i}edon*" } }
      let(:nodes_string) { "node[#{indices.first}-#{indices.last}]edon*" }

      include_examples 'expands the nodes'
    end

    context 'with a suffix and a discrete range' do
      let(:indices) { ['0', '00', '1', '02', '3', '4', '6', '007'] }
      let(:nodes) { indices.map { |i| "node#{i}edon" } }
      let(:nodes_string) { "node[#{indices.join(',')}]edon" }

      include_examples 'expands the nodes'
    end
  end
end
