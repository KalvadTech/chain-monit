require "kemal"
require "crest"
require "json"

def rpc(method)
  Crest.post(
  "http://localhost:9933",
  headers: {"Content-Type" => "application/json"},
  form: {:jsonrpc => "2.0", :id => 1, :method => method}.to_json
  )

end

get "/" do |env|
  request = rpc("system_health")
  value = JSON.parse(request.body)
  isSyncing = value["result"]["isSyncing"].as_bool
  peers = value["result"]["peers"].as_i
  shouldHavePeers = value["result"]["shouldHavePeers"].as_bool
  syncState = rpc("system_syncState")
  value = JSON.parse(syncState.body)
  currentBlock = value["result"]["currentBlock"].as_i
  highestBlock = value["result"]["highestBlock"].as_i
  startingBlock = value["result"]["startingBlock"].as_i
  env.response.content_type = "application/json"
  percentSynced = currentBlock/highestBlock*100
  if percentSynced < 0.99
    env.response.status_code = 425
  end
  if (isSyncing == false) || (peers < 5) || (shouldHavePeers == false)
    env.response.status_code = 500
  end
  {
    "isSyncing": isSyncing,
    "peers": peers,
    "shouldHavePeers": shouldHavePeers,
    "currentBlock": currentBlock,
    "highestBlock": highestBlock,
    "startingBlock": startingBlock,
    "percentSynced": percentSynced
  }.to_json
end

Kemal.run
