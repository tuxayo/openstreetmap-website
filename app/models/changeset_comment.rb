class ChangesetComment < ActiveRecord::Base
  belongs_to :changeset
  belongs_to :author, :class_name => "User"

<<<<<<< HEAD
  validates_presence_of :id, :on => :update # is it necessary?
  validates_uniqueness_of :id
  validates_presence_of :changeset
  validates_associated :changeset
  validates_presence_of :author
  validates_associated :author
  validates :visible, :inclusion => { :in => [true,false] }

  scope :visible, -> { where(visible: true) }

||||||| merged common ancestors
  validates_presence_of :id, :on => :update # is it necessary?
  validates_uniqueness_of :id
  validates_presence_of :changeset
  validates_associated :changeset
  validates_presence_of :author
  validates_associated :author
  validates :visible, :inclusion => { :in => [true,false] }
  
=======
  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :changeset, :presence => true, :associated => true
  validates :author, :presence => true, :associated => true
  validates :visible, :inclusion => [true, false]

>>>>>>> upstream/master
  # Return the comment text
  def body
    RichText.new("text", self[:body])
  end
end
