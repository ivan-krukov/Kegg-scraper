require 'sequel'
require 'set'
require 'ruby-debug'
enzymes = Sequel.connect('sqlite://enzymes.sqlite')

class Enzyme < Sequel::Model
	many_to_many :substrates
	many_to_many :products
	many_to_many :genes
	many_to_many :reactions
	many_to_many :pathways
	many_to_many :orthologies
end

class Substrate < Sequel::Model
	many_to_many :enzymes
end

class Product < Sequel::Model
	many_to_many :enzymes
end

class Gene < Sequel::Model
	many_to_many :enzymes
end

class Reaction < Sequel::Model
	many_to_many :enzymes
	many_to_many :rpairs
end

class Pathway < Sequel::Model
	many_to_many :enzymes
end

class Orthology < Sequel::Model
	many_to_many :enzymes
end

class Rpair < Sequel::Model
	many_to_many :reactions
end

#read a list of enzymes from a file, put them in a set. Also strip first two characters to get a unique pathway ID
def create_enzyme_set(file)
	return Set.new(File.open(file).read.split.map{|id| id[2..-1]})
end

energy_metabolism = create_enzyme_set('/Users/mbs/work/c_elegans_network/energy_metabolism_ids.kegg')
currency_metabolites = Set.new(File.open('/Users/mbs/work/c_elegans_network/currency_metabolites.txt').read.split /\n/)
Enzyme.each do |enzyme|
	enzyme.reactions.each do |reaction|
		#here we need to take off first two characters to get a global pathway id. We then put them in a set
		pathway_ids = enzyme.pathways.map {|id| id[2..-1]}
		if energy_metabolism.intersection pathway_ids
			reaction.rpairs.each do |rpair|
				substrate,product = rpair.pair.split '_'
				unless (currency_metabolites.include? substrate or currency_metabolites.include? product)
					if rpair.reaction_class == 'main'
						puts "#{enzyme.ec_number}\t#{substrate}\t#{product}"
					end
				end
			end
		end
	end
end
