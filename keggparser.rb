#Parser for the KEGG pages.
#First, creates an asssociated database.
#Then parse a given page and add the found data to the tables.

require 'nokogiri'
require 'sequel'

module KeggParser

	@db_name = name	

	File.delete @db_name if File.exists? @db_name

	require_relative 'create_schema'

	def parse_ec_page(content,organism)
		organism.upcase!
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
					when /Product|Substrate/
						data.text.split("\n").each do |entry|
							/\[(?<compound_id>.+?)\]/ =~ entry
							if entry.include? 'CPD'
								/(?<compound_id>C\d{5})/ =~ compound_id
							end
							compound_name = entry.slice(/[-+,'()\w\d\s]+/).strip
							if compound_id
								begin
									compound = Compound.find_or_create(:kegg_id => compound_id)
									compound.name = compound_name
									compound.save
									enzyme.add_compound(compound)
								rescue Sequel::DatabaseError
									puts "It appears that enzyme #{enzyme.ec_number} is associated with multiple compounds that have the same KEGG IDs. Only one compound will be added"
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

	def parse_reaction_page(content)
		tree = Nokogiri::HTML(content)
		table = tree.xpath('//td[@class="fr2"]/table[normalize-space()]').first
		reaction = Reaction.new
		table.search('tr').each do |row|
			title = row.search('th').text.strip
			data = row.search('td')

			case title
				when 'Entry'
					kegg_id = data.text.slice /R\d{5}/
					reaction = Reaction.find(:kegg_id => kegg_id)
				when 'Name'
					reaction.name = data.text.strip
				when 'Definition'
					reaction.definition = data.text.strip
				when 'Equation'
					reaction.equation = data.text.strip
				when 'Comment'
					reaction.comment = data.text.strip
				when 'RPair'
					data.search('tr').each do |entry|
						kegg_id, pair = entry.search('td')
						pair_entry,pair_class = pair.text.split(/\s/)
						rpair = Rpair.find_or_create(:kegg_id => kegg_id.text)
						rpair.pair = pair_entry
						rpair.reaction_class = pair_class
						rpair.save
						reaction.add_rpair(rpair)
					end
			end
			reaction.save
		end
	end

	def reaction_list
		return Reaction.kegg_id.all	
	end

end
