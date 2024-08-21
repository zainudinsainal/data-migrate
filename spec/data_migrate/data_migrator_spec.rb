# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::DataMigrator do
  let(:described_class) { DataMigrate::DataMigrator }

  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  before do
    ActiveRecord::Base.establish_connection(db_config)
    DataMigrate::RailsHelper.schema_migration.create_table
    DataMigrate::RailsHelper.data_schema_migration.create_table
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
    ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
  end

  describe ".load_migrated" do
    let(:migrator) { DataMigrate::RailsHelper.data_migrator(:up, []) }

    it "loads migrated versions" do
      DataMigrate::RailsHelper.data_schema_migration.create_version(20090000000000)
      DataMigrate::RailsHelper.schema_create_version(20100000000000)
      DataMigrate::RailsHelper.data_schema_migration.create_version(20110000000000)
      DataMigrate::RailsHelper.schema_create_version(20120000000000)
      migrated = migrator.load_migrated
      expect(migrated.count).to eq 2
      expect(migrated).to include 20090000000000
      expect(migrated).to include 20110000000000
    end
  end

  describe :create_data_schema_table do
    it "creates the data_migrations table" do
      ActiveRecord::Migration.drop_table("data_migrations") rescue nil
      described_class.create_data_schema_table
      expect(
        ActiveRecord::Base.lease_connection.table_exists?("data_migrations")
      ).to eq true
    end
  end

  describe "#migrations_status" do
    it "returns all migrations statuses" do
      status = described_class.migrations_status
      expect(status.length).to eq 2
      expect(status.first).to eq ["down", "20091231235959", "Some name"]
      expect(status.second).to eq ["down", "20171231235959", "Super update"]
    end
  end

  describe :match do
    context "when the file does not match" do
      it "returns nil" do
        expect(described_class.match("not_a_data_migration_file")).to be_nil
      end
    end

    context "when the file doesn't end in .rb" do
      it "returns nil" do
        expect(described_class.match("20091231235959_some_name.rb.un~")).to be_nil
      end
    end

    context "when the file matches" do
      it "returns a valid MatchData object" do
        match_data = described_class.match("20091231235959_some_name.rb")

        expect(match_data[0]).to eq "20091231235959_some_name.rb"
        expect(match_data[1]).to eq "20091231235959"
        expect(match_data[2]).to eq "some_name"
      end
    end
  end
end
