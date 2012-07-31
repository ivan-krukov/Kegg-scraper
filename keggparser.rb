require 'nokogiri'
require 'sequel'
require 'ruby-debug'

module KeggParser

	@@db_name = 'enzymes.sqlite'	

	File.delete @@db_name if File.exists? @@db_name

	db = Sequel.sqlite(@@db_name)

	#Data tables
	db.create_table :enzymes do
		String :ec_number, :primary_key => true, :index => true
		String :name
		String :enzyme_class
		String :sys_name
		String :iubmb_reaction
		String :comment
	end

	db.create_table :substrates do
		String :kegg_id, :primary_key => true
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
		primary_key [:enzyme_id, :substrate_id]
	end

	db.create_table :enzymes_products do
		key :enzyme_id
		key :product_id
		primary_key [:enzyme_id, :product_id]
	end

	db.create_table :enzymes_genes do
		key :enzyme_id
		key :gene_id
		primary_key [:enzyme_id, :gene_id]
	end

	db.create_table :enzymes_reactions do
		key :enzyme_id
		key :reaction_id
		primary_key [:enzyme_id, :reaction_id]
	end

	db.create_table :enzymes_pathways do
		key :enzyme_id
		key :pathway_id
		primary_key [:enzyme_id, :pathway_id]
	end

	db.create_table :enzymes_orthologies do
		key :enzyme_id
		key :orthology_id
		primary_key [:enzyme_id, :orthology_id]
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

	def KeggParser::parse_page(content)
		organism = 'cel'.upcase
		tree = Nokogiri::HTML(content)
		tables = tree.xpath('//td[@class="fr2"]/table[normalize-space()]')
		tables.each do |table|
			enzyme = Enzyme.new
			table.search('tr').each do |row|
				title = row.search('th').text.strip
				data = row.search('td')

				case title
					when 'Entry'
						ec_number = data.text.slice /([-0-9]+\.){3}[-0-9]+/
						enzyme = Enzyme.find_or_create(:ec_number => ec_number)
					when 'Name'
						enzyme.name = data.text.strip
					when 'Class'
						enzyme.enzyme_class = data.text.strip
					when 'Sysname'
						enzyme.sys_name = data.text.strip
					when 'Reaction(IUBMB)'
						enzyme.iubmb_reaction = data.text.strip
					when 'Reaction(KEGG)'
						data.text.strip.scan(/R\d{5}/).each do |entry|
							reaction = Reaction.find_or_create(:kegg_id => entry)
							enzyme.add_reaction(reaction)
						end
					when 'Substrate'

						data.text.split("\n").each do |entry|
							/\[(?<compound_id>.+?)\]/ =~ entry
							if entry.include? 'CPD'
								/(?<compound_id>C\d{5})/ =~ compound_id
							end
							compound_name = entry.slice /[-+,'()\w\d]+/
							if compound_id
								begin
								substrate = Substrate.find_or_create(:kegg_id => compound_id)
								substrate.name = compound_name
								substrate.save
								enzyme.add_substrate(substrate)
								rescue Sequel::DatabaseError
									puts "It appears that enzyme #{enzyme.ec_number} has multiple substrates with same KEGG IDs. Sadly, we have to ignore this. Only one substrate will be added"
								end
							end
						end

					when 'Product'
						data.text.split("\n").each do |entry|
							/\[(?<compound_id>.+?)\]/ =~ entry
							if entry.include? 'CPD'
								/(?<compound_id>C\d{5})/ =~ compound_id
							end
							compound_name = entry.slice /[-+,'()\w\d]+/
							if compound_id
								begin
									product = Product.find_or_create(:kegg_id => compound_id)
									product.name = compound_name
									product.save
									enzyme.add_product(product)
								rescue Sequel::DatabaseError
									puts "It appears that enzyme #{enzyme.ec_number} has multiple product with same KEGG IDs. Sadly, we have to ignore this. Only one product will be added"
								end
							end
						end
					when 'Comment'
						enzyme.comment = data.text.strip
					when 'Pathway'
						data.search('tr').each do |entry|
							pathway_id, pathway_name = entry.search('td')
							pathway = Pathway.find_or_create(:kegg_id => pathway_id.text, :name => pathway_name.text)
							enzyme.add_pathway(pathway)
						end
					when 'Orthology'
						data.search('tr').each do |entry|
							orthology_id, orthology_name = entry.search('td')
							orthology_entry = Orthology.find_or_create(:kegg_id => orthology_id.text, :name => orthology_name.text)
							enzyme.add_orthology(orthology_entry)
						end
					when 'Genes'
						data.search('tr').each do |row|
							title,content = row.search('td')
							if title.text.include? organism
								content.text.split.each do |entry|
									/(?<transcript>([.A-Z0-9]+)?)(?<name>\(.*?\))?/ =~ entry	
									name = '' unless name
									gene = Gene.find_or_create(:transcript_name => transcript, :common_name => name)
									enzyme.add_gene(gene)
								end
							end
						end
				end

				enzyme.save
			end
		end
	end
end
