class SetupHappy < ActiveRecord::Migration[5.2]
  def change
    create_table :happies do |t|
      t.string :name
      t.string :happy_type, default: "happy", index: true
      t.boolean :is_happy, default: true
      
      t.timestamps
    end
  end
end
