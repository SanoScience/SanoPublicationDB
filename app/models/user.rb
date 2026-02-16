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
    email = auth_info.fetch("info", {}).fetch("email", nil)
    role  = auth_info.fetch("extra", {}).fetch("raw_info", {}).fetch("roles", []).include?("moderator") ? :moderator : :user

    user = find_or_initialize_by(email: email)
    if user.new_record?
      # Since authentication is done via Entra ID, the password doesn't matter, so we set it randomly
      user.password = Devise.friendly_token[0, 20] if user.respond_to?(:password=)
      # In case of email/password authentication implementation, this can be changed

      user.role     = role if user.respond_to?(:role=)
      user.save!
    else
      updates = {}
      updates[:role] = role if role && user.role != role && user.respond_to?(:role=)
      user.assign_attributes(updates)
      user.save! if user.has_changes_to_save?
    end

    user
  end
end
