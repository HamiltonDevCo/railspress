class Railspress::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :wordpress, reading: :wordpress }

  def self.prefix_table_name(table_name)
    prefix =  "wp"
    "#{prefix}_#{table_name}"
  end
end
