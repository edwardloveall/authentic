require "spec"
require "../src/authentic"

LuckyRecord::Repo.configure do
  if ENV["DATABASE_URL"]?
    settings.url = ENV["DATABASE_URL"]
  else
    settings.url = LuckyRecord::PostgresURL.build(
      database: "authentic_test",
      hostname: "localhost"
    )
  end
end

Spec.before_each do
  LuckyRecord::Repo.truncate
end
