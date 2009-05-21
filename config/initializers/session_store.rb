# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_movieme_app_session',
  :secret      => '4f273e9b02915c9f8ccd1e757be686d34c3b1e684bd874c33933ef02c9d11572b2569f11096cf929c6d6e0aa8570429b7cfcfc434d3c51e60bf2e7e9e0cd448b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
