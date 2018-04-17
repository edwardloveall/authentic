require "spec"
require "../config"
require "../src/authentic"

Spec.before_each do
  LuckyRecord::Repo.truncate
end
