require 'rubygems'
require 'json'
require_relative './neo4j_controller'

class Manager
  attr_accessor :obj_hash

  def initialize
    @obj_hash = {}
    @neocon = Neo4j_controller.new
    rebuild
  end

  def write
    file = File.open("file.json","w")
    file.write(@obj_hash.to_json)
    file.close
  end

  def rebuild
    #rebuilds @obj_hash from the actual contents of Uploads
    @obj_hash = {}
    list = %x{ls Uploads | grep  -e "graph.db.tar.gz"}.split("graph.db.tar.gz\n")
    list.each do |item|
      @obj_hash[item] =  "#{item}graph.db.tar.gz"
    end
    write
  end

  def load(input = {})
    @neocon.neo4j_stop
    %x{
      cp ./Uploads/#{@obj_hash[input[:graphname]]} #{@neocon.settings[:path]}#{@neocon.settings[:version]}/data
      cd #{@neocon.settings[:path]}#{@neocon.settings[:version]}/data
      tar -zxvf #{@obj_hash[input[:graphname]]}
      rm -r #{@obj_hash[input[:graphname]]}
    }
    @neocon.neo4j_start
  end

  def new_upload(input = {})
    FileUtils.mv(input[:path], "./Uploads/#{input[:filename]}")  #this should be the only time input[:filename] is used
    @obj_hash = JSON.parse(File.read('file.json'))
    @obj_hash[input[:graphname]] = input[:filename]
    write
  end

  def delete_db(input = {})
    @obj_hash = JSON.parse(File.read('file.json'))
    %x{rm ./Uploads/#{@obj_hash[input[:graphname]]}}
    @obj_hash.delete(input[:graphname])
    write
  end

end