require "habitat"
require "lucky"
require "lucky_record"
require "./authentic/*"

module Authentic
  Habitat.create do
    # Adjustable encryption cost.
    # Typically set to a lower value in test so tests run faster
    setting encryption_cost : Int32 = 10
    setting default_password_reset_time_limit : Time::Span = 15.minutes
  end

  # Remember the originally requested path if it is a GET
  #
  # Call this if the user requested an action that requires sign in.
  # It will remember the path they requested if it is a get.
  #
  # Once the user signs in call `Authentic.redirect_to_originally_requested_path`
  # to redirect them back.
  def self.remember_requested_path(action : Lucky::Action) : Void
    if action.request.method.upcase == "GET"
      action.session[:return_to] = action.request.resource
    end
  end

  # After successful sign in, call this to redirect back to the originally request path
  #
  # First call `Authentic.remember_requested_path` if the user is not signed in.
  # Then call this to redirect them. A `fallback` action is required. The
  # `fallback` action will be used if user was not trying to access a protected
  # page before sign in.
  def self.redirect_to_originally_requested_path(
    action : Lucky::Action,
    fallback : Lucky::Action.class | Lucky::RouteHelper
  ) : Lucky::Response
    return_to = action.session[:return_to]
    action.session.delete(:return_to)
    action.redirect to: return_to || fallback
  end

  # Checks whether the password is correct
  def self.correct_password?(
    user : User,
    password_value : String
  ) : Bool
    Crypto::Bcrypt::Password.new(user.encrypted_password) == password_value
  end

  # Encrypts and sets the password
  def self.save_encrypted(
    password_field : LuckyRecord::Field | LuckyRecord::AllowedField,
    to encrypted_password_field : LuckyRecord::Field | LuckyRecord::AllowedField
  )
    password_field.value.try do |value|
      encrypted_password_field.value = create_hashed_password(value).to_s
    end
  end

  # Creates a hashed/encrypted password from a password string
  def self.create_hashed_password(password_value : String) : String
    Crypto::Bcrypt::Password.create(
      password_value,
      cost: settings.encryption_cost
    ).to_s
  end

  # Send a password reset email to the user
  def self.request_password_reset(user : User)
    RequestPasswordResetEmail.new(
      user,
      generate_password_reset_token(user)
    ).deliver
  end

  # Generates a password reset token
  def self.generate_password_reset_token(user : User, expires_in : Time::Span = Authentic.settings.default_password_reset_time_limit) : String
    encryptor = Lucky::MessageEncryptor.new(secret: Lucky::Server.settings.secret_key_base)
    encryptor.encrypt_and_sign("#{user.id}:#{expires_in.from_now.to_utc.epoch_ms}")
  end

  def self.correct_password_reset_token?(user : User, token : String) : Bool
    encryptor = Lucky::MessageEncryptor.new(secret: Lucky::Server.settings.secret_key_base)
    user_id, expiration_in_ms = String.new(encryptor.verify_and_decrypt(token)).split(":")
    Time.now.epoch_ms <= expiration_in_ms.to_i64 && user_id.to_s == user.id.to_s
  end
end
