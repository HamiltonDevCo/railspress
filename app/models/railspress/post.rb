module Railspress
  class Post < WpPost
    cattr_accessor :per_page
    validates :post_title, presence: true

    self.per_page = 10
  end
end