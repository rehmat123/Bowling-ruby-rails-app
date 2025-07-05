class CreateRolls < ActiveRecord::Migration[8.0]
  def change
    create_table :rolls do |t|
      t.references :frame, null: false, foreign_key: true
      t.integer :roll_number
      t.integer :pins

      t.timestamps
    end
  end
end
