require 'net/http/persistent'
require 'progressbar'

#The module fetches the pages from the KEGG server and stores them locally under Fetched_KEGG_data/
module KeggFetcher
	@@host = 'http://genome.jp/'
	@@query = 'dbget-bin/www_bget?'
	
	@@reaction = 'rn:'
	@@ec_number = 'ec:'

	#Fetch the pages for a given list of EC numbers
	#Type is either rn: or ec: (internally invoked)
	def KeggFetcher.download_pages(identifiers,type,output_dir)
		
		progress = ProgressBar.new('Fetching from KEGG', reactions.length)
		#format the progress bar to fit the title
		progress.format = "%-22s %3d%% %s %s"

		puts "Saving downloaded pages to #{output_dir}"

		http = Net::HTTP::Persistent.new

		identifiers.each do |id|
			#fetch page
			response = http.request URI @@host + @@query + type + id
			puts "Failed request for #{r};" unless response.class == Net::HTTPOK
			File.open(output_dir+type+id+'.html','w') do |handle|
				handle.puts response.body
			end
			progress.inc
		end 
		http.shutdown
		progress.finish
	end
end
