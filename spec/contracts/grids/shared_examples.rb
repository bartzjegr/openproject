#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

shared_context 'grid contract' do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:instance) { described_class.new(grid, user) }
  let(:default_values) do
    {
      row_count: 6,
      column_count: 7
    }
  end
  let(:grid) do
    FactoryBot.build_stubbed(:my_page_grid, default_values)
  end

  shared_examples_for 'is not writable' do
    before do
      grid.attributes = { attribute => value }
    end

    it 'is not writable' do
      expect(instance.validate)
        .to be_falsey
    end

    it 'explains the not writable error' do
      instance.validate
      expect(instance.errors.details[attribute])
        .to match_array [{ error: :error_readonly }]
    end
  end

  shared_examples_for 'is writable' do
    before do
      grid.attributes = { attribute => value }
    end

    it 'is writable' do
      expect(instance.validate)
        .to be_truthy
    end
  end

  shared_examples_for 'validates positive integer' do
    context 'when the value is negative' do
      let(:value) { -1 }

      it 'is invalid' do
        instance.validate

        expect(instance.errors.details[attribute])
          .to match_array [{ error: :greater_than, count: 0 }]
      end
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it 'is invalid' do
        instance.validate

        expect(instance.errors.details[attribute])
          .to match_array [{ error: :blank }]
      end
    end
  end
end

shared_examples_for 'shared grid contract attributes' do
  describe 'row_count' do
    it_behaves_like 'is writable' do
      let(:attribute) { :row_count }
      let(:value) { 5 }

      it_behaves_like 'validates positive integer'
    end

    context 'row_count less than 1' do
      before do
        grid.row_count = 0
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:row_count])
          .to match_array [{ error: :greater_than, count: 0 }]
      end
    end
  end

  describe 'column_count' do
    it_behaves_like 'is writable' do
      let(:attribute) { :column_count }
      let(:value) { 5 }

      it_behaves_like 'validates positive integer'
    end

    context 'row_count less than 1' do
      before do
        grid.column_count = 0
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:column_count])
          .to match_array [{ error: :greater_than, count: 0 }]
      end
    end
  end

  describe 'widgets' do
    it_behaves_like 'is writable' do
      let(:attribute) { :widgets }
      let(:value) do
        [
          GridWidget.new(start_row: 1,
                         end_row: 4,
                         start_column: 2,
                         end_column: 5,
                         identifier: 'work_packages_assigned')
        ]
      end
    end

    context 'invalid identifier' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: 4,
                           start_column: 2,
                           end_column: 5,
                           identifier: 'bogus_identifier')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :inclusion }]
      end
    end

    context 'collisions between widgets' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: 3,
                           start_column: 1,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
        grid.widgets.build(start_row: 2,
                           end_row: 4,
                           start_column: 2,
                           end_column: 4,
                           identifier: 'work_packages_created')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :overlaps }, { error: :overlaps }]
      end
    end

    context 'widgets having the same start column as another\'s end column' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: 3,
                           start_column: 1,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
        grid.widgets.build(start_row: 1,
                           end_row: 3,
                           start_column: 3,
                           end_column: 4,
                           identifier: 'work_packages_created')
      end

      it 'is valid' do
        expect(instance.validate)
          .to be_truthy
      end
    end

    context 'widgets having the same start row as another\'s end row' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: 3,
                           start_column: 1,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
        grid.widgets.build(start_row: 3,
                           end_row: 4,
                           start_column: 1,
                           end_column: 3,
                           identifier: 'work_packages_created')
      end

      it 'is valid' do
        expect(instance.validate)
          .to be_truthy
      end
    end

    context 'widgets being outside (max) of the grid' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: grid.row_count + 2,
                           start_column: 1,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :outside }]
      end
    end

    context 'widgets being outside (min) of the grid' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: 2,
                           start_column: -1,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :outside }]
      end
    end

    context 'widgets spanning the whole grid' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: grid.row_count + 1,
                           start_column: 1,
                           end_column: grid.column_count + 1,
                           identifier: 'work_packages_assigned')
      end

      it 'is valid' do
        expect(instance.validate)
          .to be_truthy
      end
    end

    context 'widgets having start after end column' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: 2,
                           start_column: 4,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :end_before_start }]
      end
    end

    context 'widgets having start after end row' do
      before do
        grid.widgets.build(start_row: 4,
                           end_row: 2,
                           start_column: 1,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :end_before_start }]
      end
    end

    context 'widgets having start equals end column' do
      before do
        grid.widgets.build(start_row: 1,
                           end_row: 2,
                           start_column: 4,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :end_before_start }]
      end
    end

    context 'widgets having start equals end row' do
      before do
        grid.widgets.build(start_row: 2,
                           end_row: 2,
                           start_column: 1,
                           end_column: 3,
                           identifier: 'work_packages_assigned')
      end

      it 'is invalid' do
        expect(instance.validate)
          .to be_falsey
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :end_before_start }]
      end
    end
  end

  describe 'valid grid subclasses' do
    context 'for a registered subclass' do
      let(:grid) do
        FactoryBot.build_stubbed(:my_page_grid, default_values)
      end

      it 'is valid' do
        expect(instance.validate)
          .to be_truthy
      end
    end

    context 'for the Grid superclass itself' do
      let(:grid) do
        FactoryBot.build_stubbed(:grid, default_values)
      end

      before do
        instance.validate
      end

      it 'is invalid for the grid superclass itself' do
        expect(instance.errors.details[:page])
          .to match_array [{ error: :inclusion }]
      end
    end
  end
end
