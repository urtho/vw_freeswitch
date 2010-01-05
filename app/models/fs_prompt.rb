
class FsPrompt < ActiveRecord::Base
  has_many :fs_extensions
  dependent_restrict :fs_extensions
#  validate_fields self
end
