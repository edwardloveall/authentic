module Authentic::PasswordAuthenticatable
  abstract def email : String
  abstract def encrypted_password : String
end
