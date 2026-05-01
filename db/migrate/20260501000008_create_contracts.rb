class CreateContracts < ActiveRecord::Migration[7.2]
  def change
    create_table "contracts", force: :cascade do |t|
      t.string "person_slug", null: false
      t.string "team_slug", null: false
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.date "expires_at"
      t.bigint "annual_value_cents"
      t.string "position"
      t.string "contract_type", default: "active"
      t.index ["contract_type"], name: "index_contracts_on_contract_type"
      t.index ["expires_at"], name: "index_contracts_on_expires_at"
      t.index ["person_slug", "team_slug"], name: "index_contracts_on_person_slug_and_team_slug", unique: true
      t.index ["person_slug"], name: "index_contracts_on_person_slug"
      t.index ["slug"], name: "index_contracts_on_slug", unique: true
      t.index ["team_slug"], name: "index_contracts_on_team_slug"
    end
  end
end
