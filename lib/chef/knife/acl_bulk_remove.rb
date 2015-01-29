#
# Author:: Jeremiah Snapp (jeremiah@chef.io)
# Copyright:: Copyright 2011--2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module OpscodeAcl
  class AclBulkRemove < Chef::Knife
    category "OPSCODE HOSTED CHEF ACCESS CONTROL"
    banner "knife acl bulk remove OBJECT_TYPE REGEX PERMS MEMBER_TYPE MEMBER_NAME"

    attr_reader :object_type, :object_name_matcher, :perms, :member_type, :member_name

    deps do
      include OpscodeAcl::AclBase
    end

    def run
      @object_type, regex, @perms, @member_type, @member_name = name_args
      @object_name_matcher = /#{regex}/

      if name_args.length != 5
        show_usage
        ui.fatal "You must specify the object_type, object_name, perms, member type [client|group|user] and member name"
        exit 1
      end

      validate_perm_type!(perms)
      validate_member_type!(member_type)
      validate_member_name!(member_name)
      validate_object_type!(object_type)
      validate_member_exists!(member_type, member_name)

      if %w(containers groups).include?(object_type)
        ui.fatal "bulk modifying the ACL of #{object_type} is not permitted"
        exit 1
      end

      objects_to_modify = []
      all_objects = rest.get_rest(object_type)
      objects_to_modify = all_objects.keys.select { |object_name| object_name =~ object_name_matcher }

      if objects_to_modify.empty?
        ui.info "No #{object_type} match the expression /#{regex}/"
        exit 0
      end

      ui.msg("The ACL of the following #{object_type} will be modified:")
      ui.msg("")
      ui.msg(ui.list(objects_to_modify.sort, :columns_down))
      ui.msg("")
      ui.confirm("Are you sure you want to modify the ACL of these #{object_type}?")

      objects_to_modify.each do |object_name|
        remove_from_acl!(object_type, object_name, member_type, member_name, perms)
      end
    end
  end
end