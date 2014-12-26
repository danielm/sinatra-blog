# Tag/Post relations
class Tagging < ActiveRecord::Base
  belongs_to :post
  belongs_to :tag
end

# Tag
class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy
  has_many :posts, :through => :taggings

  before_save :create_slug

  def url
    "tag/#{self.slug}/"
  end

  def create_slug
    self.slug = self.name.parameterize
  end
end

# Categories model
class Category < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 5, maximum: 255  }
  validates :slug, uniqueness: { case_sensitive: false }

  has_many :posts

  before_validation :create_slug

  def url
    "#{self.slug}/"
  end

  def create_slug
    self.slug = self.name.parameterize
  end
end

# Posts Model
class Post < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy
  has_many :tags, :through => :taggings

  belongs_to :category

  validates :title, presence: true, length: { minimum: 5, maximum: 255  }
  validates :slug, uniqueness: { case_sensitive: false }
  validates :body, presence: true

  before_validation :create_slug
  after_save :assign_tags

  attr_writer :tag_names

  def tag_names
    @tag_names || tags.map(&:name).join(',')
  end

  def rfc_date
    Time.parse(self.published_on.to_s).rfc822()
  end 

  def url
    "post/" + self.published_on.strftime("%Y/%m/%d") + "/#{self.slug}.html"
  end

  def create_slug
    self.slug = self.title.parameterize
  end

private
  
  def assign_tags
    if @tag_names
      self.tags = @tag_names.split(/, */).map do |name|
        name.strip!
        Tag.where(:slug => name.parameterize).first_or_create(:name => name)
      end
    end
  end
end

# Messages Model
class Message < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 255  }
  validates :email, presence: true, length: { maximum: 255  }
  validates :body, presence: true
  validates_format_of :email, :with => /\A[^@]+@([^@\.]+\.)+[^@\.]+\z/, :message => "is not a valid e-mail address"
end

# Pages Model
class Page < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 5, maximum: 255  }
  validates :slug, uniqueness: { case_sensitive: false }
  validates :body, presence: true

  before_validation :create_slug

  def url
    "p/#{self.slug}.html"
  end

  def create_slug
    self.slug = self.title.parameterize
  end
end
