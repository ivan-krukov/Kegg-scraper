#Data tables
DB.create_table :enzymes do
	String :ec_number, :primary_key => true, :index => true
	String :name
	String :enzyme_class
	String :sys_name
	String :iubmb_reaction
	String :comment
end

DB.create_table :compounds do
	String :kegg_id, :primary_key => true
	String :name
end

DB.create_table :genes do
	String :transcript_name, :primary_key => true
	String :common_name
end

DB.create_table :reactions do
	String :kegg_id, :primary_key => true
	String :name
	String :definition
	String :equation
	String :comment
end

DB.create_table :rpairs do
	String :kegg_id, :primary_key => true
	String :pair
	String :reaction_class
end

DB.create_table :pathways do
	String :kegg_id, :primary_key => true
	String :name
end

DB.create_table :orthologies do
	String :kegg_id, :primary_key => true
	String :name
end

#Association tables

DB.create_table :compounds_enzymes do
	key :compound_id
	key :enzyme_id
	primary_key [:compound_id, :enzyme_id]
end

DB.create_table :enzymes_genes do
	key :enzyme_id
	key :gene_id
	primary_key [:enzyme_id, :gene_id]
end

DB.create_table :enzymes_reactions do
	key :enzyme_id
	key :reaction_id
	primary_key [:enzyme_id, :reaction_id]
end

DB.create_table :enzymes_pathways do
	key :enzyme_id
	key :pathway_id
	primary_key [:enzyme_id, :pathway_id]
end

DB.create_table :enzymes_orthologies do
	key :enzyme_id
	key :orthology_id
	primary_key [:enzyme_id, :orthology_id]
end

DB.create_table :reactions_rpairs do
	key :reaction_id
	key :rpair_id
	primary_key [:reaction_id, :rpair_id]
end
