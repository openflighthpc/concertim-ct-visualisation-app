object false
node(:timestamp) do
  Time.new.to_i
end
node(:added) do 
  @added.map(&:id)
end
node(:modified) do 
  @modified.map(&:id)
end
node(:deleted) do
  @deleted
end
