# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string(255)
#  role                   :integer
#  address                :string(255)
#  phone                  :string(255)
#  professional_email     :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  subscription           :integer          default(0)
#  discount               :decimal(, )      default(0.0)
#  subscribed_at          :datetime
#  referral_code          :string
#  referral_count         :integer
#  reimbursement_method   :text
#  referrer_id            :integer
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ActiveRecord::Base
  enum role: [:user, :admin]
  enum subscription: [:free, :premium]
  has_many :award_notes
  has_many :activity_notes
  has_many :experiences
  has_many :degrees
  has_many :languages
  has_many :patents
  has_many :publications
  has_many :resumes
  has_many :skill_notes
  has_many :test_scores
  has_many :universities
  has_one :other_section_note
  after_initialize :set_default_role, :if => :new_record?

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def set_default_role
    self.role ||= :user
  end

  def set_premium
    self.update(subscription: :premium, subscribed_at: DateTime.current)
  end

  def update_contact_info_params(params)
    self.update_attributes(params[:user].permit(
      :name,
      :address,
      :phone,
      :professional_email
    ))
  end

  def get_experiences(type)
    type_num = Experience.experience_types[type]
    collection = Experience.where(user_id: self.id,
                                  experience_type: type_num)

    if collection.empty?
      collection.create(experience_type: type_num)
    end

    return collection
  end


  def get_activities(type)
    type_num = ActivityNote.activity_types[type]
    collection = ActivityNote.where(user_id: self.id,
                                    activity_type: type_num)

    if collection.empty?
      collection.create(activity_type: type_num)
    end

    return collection
  end

end
