#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe "PATCH /api/v3/grids/:id/form", type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:current_user) do
    FactoryBot.create(:user)
  end

  let(:grid) do
    grid = MyPageGrid.new_default(current_user)
    grid.save!
    grid
  end
  let(:path) { api_v3_paths.grid_form(grid.id) }
  let(:params) { {} }
  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe '#post' do
    before do
      post path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'returns 200 OK' do
      expect(subject.status)
        .to eql 200
    end

    it 'is of type form' do
      expect(subject.body)
        .to be_json_eql("Form".to_json)
        .at_path('_type')
    end

    it 'contains a Schema disallowing setting page' do
      expect(subject.body)
        .to be_json_eql("Schema".to_json)
        .at_path('_embedded/schema/_type')

      expect(subject.body)
        .to be_json_eql(false.to_json)
        .at_path('_embedded/schema/page/writable')
    end

    it 'contains the current data in the payload' do
      expected = {
        "rowCount": 4,
        "columnCount": 5,
        "widgets": [
          {
            "_type": "GridWidget",
            "identifier": "work_packages_assigned",
            "startRow": 4,
            "endRow": 5,
            "startColumn": 1,
            "endColumn": 2
          },
          {
            "_type": "GridWidget",
            "identifier": "work_packages_created",
            "startRow": 1,
            "endRow": 2,
            "startColumn": 1,
            "endColumn": 2
          },
          {
            "_type": "GridWidget",
            "identifier": "work_packages_watched",
            "startRow": 2,
            "endRow": 4,
            "startColumn": 4,
            "endColumn": 5
          },
          {
            "_type": "GridWidget",
            "identifier": "work_packages_calendar",
            "startRow": 1,
            "endRow": 2,
            "startColumn": 4,
            "endColumn": 6
          }
        ],
        "_links": {
          "page": {
            "href": "/my/page",
            "type": "text/html"
          }
        }
      }

      expect(subject.body)
        .to be_json_eql(expected.to_json)
        .at_path('_embedded/payload')
    end

    it 'has a commit link' do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.grid(grid.id).to_json)
        .at_path('_links/commit/href')
    end

    context 'with some value for the page value' do
      let(:params) do
        {
          '_links': {
            'page': {
              'href': '/some/path'
            }
          }
        }
      end

      it 'has a validation error on page as the value is not writeable' do
        expect(subject.body)
          .to be_json_eql("You must not write a read-only attribute.".to_json)
          .at_path('_embedded/validationErrors/page/message')
      end
    end

    context 'with an unsupported widget identifier' do
      let(:params) do
        {
          "widgets": [
            {
              "_type": "GridWidget",
              "identifier": "bogus_identifier",
              "startRow": 4,
              "endRow": 5,
              "startColumn": 1,
              "endColumn": 2
            }
          ]
        }
      end

      it 'has a validationError on widget' do
        expect(subject.body)
          .to be_json_eql("Widgets is not set to one of the allowed values.".to_json)
          .at_path('_embedded/validationErrors/widgets/message')
      end
    end
  end
end
