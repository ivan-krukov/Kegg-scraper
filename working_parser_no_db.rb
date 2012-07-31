require 'nokogiri'
require 'sequel'
require 'ruby-debug'
class KeggEnzyme
	attr_writer :ec_number,
	 			:name,
				:enzyme_class, 
				:sys_name,
				:iubmb_reaction, 
				:reactions,
				:substrates, 
				:products, 
				:comment, 
				:pathways, 
				:orthology, 
				:genes
	attr_reader :ec_number,
	 			:name,
				:enzyme_class, 
				:sys_name,
				:iubmb_reaction, 
				:reactions,
				:substrates, 
				:products, 
				:comment, 
				:pathways, 
				:orthology, 
				:genes

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
		"EC:\t#{ec_number}\nName:\t#{name}\nClass:\t#{enzyme_class}\nEquation:\t#{iubmb_reaction}\nComment:\t#{comment}\nSubstrates:\t#{substrates}\nProducts:\t#{products}\nReactions:\t#{reactions}\nPathways:\t#{pathways}\nOrthology:\t#{orthology}\nGenes:#{genes}\n"
	end
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

	db.create_table :genes do
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
	enzymes = Array.new
	
	`rm enzymes.db`
	enzyme_db = Sequel.sqlite('enzymes.db')
	create_tables(enzyme_db)

	organism = 'cel'.upcase
	tree = Nokogiri::HTML(File.open('ec_entry.html'))
	tables = tree.xpath('//td[@class="fr2"]/table[normalize-space()]')
	tables.each do |table|
		enzyme = KeggEnzyme.new
		table.search('tr').each do |row|
			title = row.search('th').text.strip
			data = row.search('td')
			#debugger
			case title
				when 'Entry'
					enzyme.ec_number = data.text.slice /(\d+\.){3}\d+/
				when 'Name'
					enzyme.name = data.text.strip
				when 'Class'
					enzyme.enzyme_class = data.text.strip
				when 'Sysname'
					enzyme.sys_name = data.text.strip
				when 'Reaction(IUBMB)'
					enzyme.iubmb_reaction = data.text.strip
				when 'Reaction(KEGG)'
					enzyme.reactions = data.text.strip.scan /R\d{5}/
				when 'Substrate'
					enzyme.substrates = data.text.split /\n/
				when 'Product'
					enzyme.products = data.text.split /\n/
				when 'Comment'
					enzyme.comment = data.text.strip
				when 'Pathway'
					enzyme.pathways = data.search('tr').map {|cell| cell.text}
				when 'Orthology'
					enzyme.orthology = data.search('tr').map {|cell| cell.text}
				when 'Genes'
					data.search('tr').each do |row|
						title,content = row.search('td')
						if title.text.include? organism
							enzyme.genes = content.text.split	
						end
					end

			end
		end

		enzymes << enzyme
	end

	puts enzymes

end

class Enzyme < Sequel::Model
	unrestrict_primary_key
	many_to_many :substrates
	many_to_many :products
	many_to_many :genes
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
