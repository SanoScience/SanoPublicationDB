class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[entra_id]

  has_many :publications, foreign_key: :owner_id, dependent: :nullify

  enum :role, {
    user: 0,
    moderator: 1
  }

  def self.from_omniauth(auth_info)
    email = auth_info["info"]["email"]
    name  = auth_info["info"]["name"]

    user = find_or_initialize_by(email: email)
    if user.new_record?
      user.name     = name if user.respond_to?(:name=)
      user.password = Devise.friendly_token[0, 20]
      user.role     = :user
      user.save!
    end
    user
  end
end
