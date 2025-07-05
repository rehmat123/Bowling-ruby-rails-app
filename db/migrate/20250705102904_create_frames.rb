class CreateFrames < ActiveRecord::Migration[8.0]
  def change
    create_table :frames do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :number

      t.timestamps
    end
  end
end
