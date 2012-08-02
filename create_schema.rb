DB = Sequel.sqlite(@db_name)

require_relative 'create_tables'

class Enzyme < Sequel::Model
	unrestrict_primary_key
	many_to_many :compunds
	many_to_many :genes
	many_to_many :reactions
	many_to_many :pathways
	many_to_many :orthologies
end

class Compound < Sequel::Model
	unrestrict_primary_key
	many_to_many :enzymes
end

class Gene < Sequel::Model
	unrestrict_primary_key
	many_to_many :enzymes
end

class Reaction < Sequel::Model
	unrestrict_primary_key
	many_to_many :enzymes
end

class Pathway < Sequel::Model
	unrestrict_primary_key
	many_to_many :enzymes
end

class Orthology < Sequel::Model
	unrestrict_primary_key
	many_to_many :enzymes
end
