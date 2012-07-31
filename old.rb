require 'nokogiri'
require 'sequel'
class Reaction
	attr_writer :ec, :kegg_id, :name, :definition, :comment, :reaction_pairs, :enzymes, :pathways, :orthology
	attr_reader :ec, :kegg_id, :name, :definition, :comment, :equation, :substrates, :products, :reaction_pairs, :enzymes, :pathways, :orthology

	@@stoichiometry = /^\d+\s|\s\d+\s|\(.*?\)/

	def equation=(line)
		@equation = line.dup
		line.gsub!(@@stoichiometry,' ')
		substrates,products = line.split(' <=> ')
		#puts products
		@substrates = substrates.split(' + ')
		@products = products.split(' + ')
	end

	def to_s
		"EC:\t#{ec}\nKEGG_ID:\t#{kegg_id}\nName:\t#{name}\nDefinition:\t#{definition}\nEquation:\t#{equation}\nComment:\t#{comment}\nRPairs:\t#{reaction_pairs}\nEnzymes:\t#{enzymes}\nPathways:\t#{pathways}\nOrthology:\t#{orthology}\n"
	end
end




class Enzyme < Sequel::Model
	unrestrict_primary_key
	many_to_many :substrates
	many_to_many :products
	many_to_many :peptides
	many_to_many :reactions
	many_to_many :pathways
	many_to_many :orthologies

end

class Substrate < Sequel::Model
	unrestrict_primary_key
	many_to_many :enzymes
end

class Product < Sequel::Model
	unrestrict_primary_key
	many_to_many :enzymes
end

class Peptide < Sequel::Model
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

#Just a separate namespace for the table initiation stuff
def create_tables (db)

	#Data tables
	db.create_table :enzymes do
		String :ec_number, :primary_key => true
		String :name
		String :class
		String :iubmb_reaction
		String :comment
	end

	db.create_table :substrates do
		String :kegg_if, :primary_key => true
		String :name
	end
	
	db.create_table :products do
		String :kegg_id, :primary_key => true
		String :name
	end

	db.create_table :peptides do
		String :transcript_name, :primary_key => true
		String :common_name
	end

	db.create_table :reactions do
		String :kegg_id, :primary_key => true
	end

	db.create_table :pathways do
		String :kegg_id, :primary_key => true
		String :name
	end

	db.create_table :orthologies do
		String :kegg_id, :primary_key => true
		String :name
	end

	#Association tables
	db.create_table :enzymes_substrates do
		key :enzyme_id
		key :substrate_id
	end

	db.create_table :enzymes_products do
		key :enzyme_id
		key :product_id
	end

	db.create_table :enzymes_peptides do
		key :enzyme_id
		key :peptide_id
	end

	db.create_table :enzymes_reactions do
		key :enzyme_id
		key :reaction_id
	end
	
	db.create_table :enzymes_pathways do
		key :enzyme_id
		key :pathway_id
	end

	db.create_table :enzymes_orthologies do
		key :enzyme_id
		key :orthology_id
	end

end


if __FILE__ == $0
	reactions = Array.new
	
	enzyme_db = Sequel.sqlite('enzymes.db')

	tree = Nokogiri::HTML(File.open('list_example.html'))
	tables = tree.xpath('//td[@class="fr2"]/table[normalize-space()]')
	tables.each do |table|
		reaction = Reaction.new
		table.search('tr').each do |row|
			title = row.search('th').text.strip
			data = row.search('td')
			#debugger
			case title
				when 'Entry'
					reaction.kegg_id = data.text.slice /\w+/
				when 'Name'
					reaction.name = data.text.strip
				when 'Definition'
					reaction.definition = data.text.strip
				when 'Equation'
					reaction.equation = data.text.strip
				when 'Comment'
					reaction.comment = data.text.strip
				when 'RPair'
					reaction.reaction_pairs = data.search('tr').map {|cell| cell.text}
				when 'Enzyme'
					reaction.enzymes = data.text.split /\u00A0+/
				when 'Pathway'
					reaction.pathways = data.search('tr').inject {|string, cell| string << cell.text}
				when 'Orthology'
					reaction.orthology = data.search('tr').map {|cell| cell.text}
			end
		end

		reactions << reaction
	end

end
