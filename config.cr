require "lucky_migrator"

database = "authentic_test"

LuckyRecord::Repo.configure do
  if ENV["DATABASE_URL"]?
    settings.url = ENV["DATABASE_URL"]
  else
    settings.url = LuckyRecord::PostgresURL.build(
      database: database,
      hostname: "localhost"
    )
  end
end

LuckyMigrator::Runner.configure do
  settings.database = database
end
