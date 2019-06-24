# frozen_string_literal: true

# =============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Architect.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Architect is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Architect. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Architect, please visit:
# https://github.com/openflighthpc/flight-architect
# ==============================================================================

require 'nodeattr_utils/config'

RSpec.describe NodeattrUtils::Config do
  before do
    allow(described_class).to receive(:path).and_return('/tmp/test-path')
  end

  shared_context 'with a Config instance' do
    let(:cluster_name) { 'my-test-cluster' }
    subject { described_class.new(cluster_name) }
  end

  shared_context 'with the first group' do
    let(:first_group) { 'my-first-group' }
    before { subject.add_group(first_group) }
  end

  context 'without any additional groups or nodes' do
    include_context 'with a Config instance'

    describe '#raw_groups' do
      it 'contains the orphan group' do
        expect(subject.raw_groups).to include('orphan')
      end
    end

    describe '#remove_group' do
      it 'does nothing' do
        expect do
          subject.remove_group('missing')
        end.not_to raise_error
      end

      it 'errors when deleting the orphan group' do
        expect do
          subject.remove_group('orphan')
        end.to raise_error(NodeattrUtils::RemovingOrphanGroupError)
      end
    end

    describe '#remove_nodes' do
      it 'does nothing' do
        expect do
          subject.remove_nodes('missing[1-10]')
        end.not_to raise_error
      end
    end

    describe '#nodes_list' do
      it 'is initially an empty array' do
        expect(subject.nodes_list).to eq([])
      end
    end

    describe '#group_index' do
      it 'returns nil for missing groups' do
        expect(subject.group_index('some-missing-group')).to eq(nil)
      end

      it 'returns 0 for the orphan group' do
        expect(subject.group_index('orphan')).to eq(0)
      end
    end

    describe '#orphans' do
      it 'is initially an empty array' do
        expect(subject.orphans).to eq([])
      end
    end

    describe '#nodes_in_group' do
      it 'returns an empty array when there are no nodes' do
        expect(subject.nodes_in_group('some-random-group')).to eq([])
      end
    end
  end

  context 'when adding a single group' do
    include_context 'with a Config instance'
    include_context 'with the first group'

    describe '#add_group' do
      let!(:original_index) { subject.group_index(first_group) }

      before do
        # Adds another group to make the spec more realistic
        subject.add_group('some-other-group')

        # Ensure the original_index is set
        original_index
        subject.add_group(first_group)
      end

      it 'does not re add the group' do
        expect(subject.raw_groups.count(first_group)).to eq(1)
      end

      it 'does not change the index' do
        expect(subject.group_index(first_group)).to eq(original_index)
      end
    end

    describe '#remove_group' do
      let(:second_group) { 'my-second-group' }
      let!(:second_group_index) {}
      let(:first_node) { 'first_group_node' }
      let(:second_node) { 'second_group_node' }

      before do
        subject.add_nodes(first_node, groups: [first_group, second_group])
        subject.add_nodes(second_node, groups: [second_group, first_group])
      end

      it 'preserves latter groups index' do
        original_index = subject.group_index(second_group)
        subject.remove_group(first_group)
        expect(subject.group_index(second_group)).to eq(original_index)
      end

      context 'with the first group removed' do
        before { subject.remove_group(first_group) }

        it 'removes the group' do
          expect(subject.raw_groups).not_to include(first_group)
        end

        it 'removes the groups primary nodes' do
          expect(subject.nodes_list).not_to include(first_node)
        end

        it 'does not remove the secondary nodes' do
          expect(subject.nodes_list).to include(second_node)
        end

        describe '#groups_hash' do
          it 'does not include nil as a key' do
            expect(subject.groups_hash.keys).not_to include(nil)
          end
        end

        describe '#group_index' do
          it 'returns nil for the nil group' do
            expect(subject.group_index(nil)).to be(nil)
          end
        end
      end
    end

    describe '#raw_groups' do
      it 'contains the group' do
        expect(subject.raw_groups).to include(first_group)
      end
    end

    describe '#group_index' do
      it 'returns 1 for the first group' do
        expect(subject.group_index(first_group)).to eq(1)
      end
    end

    describe '#groups_hash' do
      it 'returns key-value pairs of names to indices' do
        expect(subject.groups_hash).to include(first_group => 1, 'orphan' => 0)
      end
    end
  end

  context 'when adding nodes' do
    include_context 'with a Config instance'

    let(:node_str) { 'node[01-10]' }
    let(:nodes) { NodeattrUtils::Nodes.expand(node_str) }
    let(:node_groups) { nil }

    before do
      if node_groups
        subject.add_nodes(node_str, groups: node_groups)
      else
        subject.add_nodes(node_str)
      end
    end

    describe '#add_nodes' do
      let(:new_groups) { ['new_group1', 'new_group2'] }
      before { subject.add_nodes(node_str, groups: new_groups) }

      it 'does not duplicate the node entry' do
        expect(subject.nodes_list.count(nodes.first)).to eq(1)
      end

      it 'updates the groups entry' do
        expect(subject.groups_for_node(nodes.first)).to eq(new_groups)
      end

      it 'implicitly adds the primary group' do
        expect(subject.groups_hash.keys).to include(new_groups.first)
        expect(subject.groups_hash.keys).not_to include(new_groups.last)
      end
    end

    describe '#remove_nodes' do
      before { subject.add_nodes(node_str) }

      it 'can remove a single node only' do
        delete_node = nodes.shift
        subject.remove_nodes(delete_node)
        expect(subject.nodes_list).not_to include(delete_node)
        expect(subject.nodes_list).to include(*nodes)
      end

      it 'can remove a range of nodes' do
        subject.remove_nodes(node_str)
        expect(subject.nodes_list).not_to include(*nodes)
      end
    end

    context 'without any groups' do
      describe '#nodes_list' do
        it 'returns the node list' do
          expect(subject.nodes_list).to contain_exactly(*nodes)
        end
      end

      describe '#groups_for_node' do
        it 'is placed in the orphan group' do
          expect(subject.groups_for_node(nodes.first)).to eq(['orphan'])
        end
      end

      describe '#orphans' do
        it 'includes the nodes' do
          expect(subject.orphans).to contain_exactly(*nodes)
        end
      end
    end

    context 'when adding them to the first group' do
      include_context 'with the first group'

      let(:node_groups) { first_group }

      describe '#groups_for_node' do
        it 'returns an array of the group' do
          expect(subject.groups_for_node(nodes.first)).to contain_exactly(first_group)
        end
      end
    end

    context 'when adding multiple missing groups' do
      let(:node_groups) { ['missing1', 'missing2'] }

      describe '#groups_for_node' do
        it 'returns the missing groups in the correct order' do
          expect(subject.groups_for_node(nodes.first)).to eq(node_groups)
        end
      end
    end
  end

  context 'when adding multiple nodes' do
    include_context 'with a Config instance'
    let(:group1) { 'group1' }
    let(:primary_prefix) { 'primary_' }
    let(:base_group1_nodes) { ['node1', 'node2', 'node4'] }
    let(:primary_group1_nodes) do
      base_group1_nodes.map { |n| "#{primary_prefix}#{n}" }
    end
    let(:group1_nodes) do
      [base_group1_nodes, primary_group1_nodes].flatten
    end

    # Other nodes are injected in to make the example more realistic
    before do
      base_group1_nodes.each do |node|
        subject.add_nodes(node, groups: ['other', group1])
        subject.add_nodes("#{primary_prefix}#{node}", groups: group1)
        subject.add_nodes("not_#{node}")
      end
    end

    describe '#nodes_in_group' do
      it 'returns a specific group of nodes' do
        expect(subject.nodes_in_group('group1')).to contain_exactly(*group1_nodes)
      end
    end

    describe '#nodes_in_primary_group' do
      it 'only returns the primary nodes' do
        expect(subject.nodes_in_primary_group(group1)).to contain_exactly(*primary_group1_nodes)
      end
    end
  end
end
