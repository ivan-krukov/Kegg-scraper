#!/usr/bin/env ruby

#The program takes a list of EC numbers in a file one per line.
#It fetches the EC entries and their respective reactions from the KEGG website.
#Each of the downloaded pages is then parsed and the data is stored in an SQLite database.
#
#Author:: Ivan Kryukov (mailto:ikryukov@ucalgary.ca)
#License:: WTFPL (http://sam.zoy.org/wtfpl/)


require 'trollop'
require 'progressbar'
require 'ruby-debug'
require_relative 'keggfetcher'
require_relative 'keggparser'

if __FILE__ == $0
	#Get the arguments
	args = Trollop::options do
		opt :file, 'Input KEGG reactions number list', :type=>String, :required=>true
		opt :input_pages, 'A directory containing the input data', :type=>String
	end
	Trollop::die :file, "Provided reaction file does not exist" unless File.exist?(args[:file]) if args[:file]
	
	#download the pages if needed
	unless args[:input_pages] and Dir.exists?(args[:input_pages])
		pages_dir = 'Fetched_KEGG_data/'
		enzymes = File.open(args[:file]).read.split
		KeggFetcher.download_pages(enzymes,'ec:',pages_dir)
	else
		pages_dir = args[:input_pages]
	end
	
	#First, process the EC number entries
	ec_entries = Dir.glob("#{pages_dir}ec:*.html")
	progress = ProgressBar.new('Parsing ECs',ec_entries.length)
	progress.format = "%-20s %3d%% %s %s"
	
	ec_entries.each do |page|
		text = File.open(page).read
		KeggParser.parse_ec_page(text,'cel')
		progress.inc
	end
	progress.finish

	#try to fetch the reaction data based on the enzyme entries
	unless args[:input_pages] and Dir.exists?(args[:input_pages])
		reactions = KeggParser.reaction_list
		KeggFetcher.download_pages(reactions,'rn:',pages_dir)
	end

	#Now parse the reaction data
	reaction_entries = Dir.glob("#{pages_dir}rn:*.html")
	progress = ProgressBar.new('Parsing reaction data',reaction_entries.length)
	progress.format = "%-20s %3d%% %s %s"

	reaction_entries.each do |page|
		text = File.open(page).read
		KeggParser.parse_reaction_page(text)
		progress.inc
	end
	progress.finish

end

