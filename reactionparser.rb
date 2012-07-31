require 'nokogiri'
require 'sequel'
require 'ruby-debug'

module ReactionParser

	@@db_name = 'sqlite://enzymes.sqlite'	

	db = Sequel.connect(@@db_name)

	#Data tables
	db.alter_table(:reactions) do
		add_column :name, String
		add_column :definition, String
		add_column :equation, String
		add_column :comment, String
	end

	db.create_table :rpairs do
		String :kegg_id, :primary_key => true
		String :reaction_class
		String :pair
	end
	#Association tables
	db.create_table :reactions_rpairs do
		key :reaction_id
		key :rpair_id
		primary_key [:reaction_id, :rpair_id]
	end

	class Reaction < Sequel::Model
		many_to_many :rpairs
	end

	class Rpair < Sequel::Model
		unrestrict_primary_key
		many_to_many :reactions
	end
	
	def ReactionParser::parse_page(content)
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
end
