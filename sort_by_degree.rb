require 'ruby-debug'

class Node
	attr_reader :degree, :name
	def initialize (name, degree)
		@name = name
		@degree = degree
	end
end

nodes = Array.new
lines = File.open('c_elegans_0.0.1_degrees.txt').read.split /\n/

lines.each do |line|
	name,degree = line.split /\s/
	nodes<<Node.new(name,degree.to_i)
end

#sort in reverse order
nodes.sort! {|x,y| y.degree <=> x.degree}
nodes.each {|n| puts "#{n.name}\t#{n.degree}"}
