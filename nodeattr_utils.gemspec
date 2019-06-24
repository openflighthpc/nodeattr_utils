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
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nodeattr_utils/version"

Gem::Specification.new do |spec|
  spec.name          = "nodeattr_utils"
  spec.version       = NodeattrUtils::VERSION
  spec.authors       = ["Alces Flight Ltd"]
  spec.email         = ["flight@openflighthpc.org"]
  spec.license       = 'EPL-2.0'
  spec.summary       = %q{Ruby implementation of nodeattr behaviour}
  spec.homepage      = "https://github.com/openflighthpc/nodeattr_utils"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'flight_config', '~>0.2'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
end
